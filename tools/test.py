#!/usr/bin/env python3
"""Check fixtures, expected diagnostics, and reproducible PDF hashes."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    temporary.replace(path)


def accept_review(parser, baseline_path, review_dir, selected):
    report_path = review_dir / "review.json"
    if not report_path.exists():
        parser.error("No pending review. Run tools/test.py and inspect the changed PDFs first.")
    report = json.loads(report_path.read_text())
    if report["failures"]:
        parser.error("Cannot accept hashes from a run with compilation or diagnostic failures.")
    if report["baseline_sha256"] != digest(baseline_path):
        parser.error("The baseline changed since this review. Run tools/test.py again.")
    changes = set(report["changes"])
    chosen = changes if selected == ["all"] else set(selected)
    if not chosen or not chosen <= changes:
        parser.error("Select pending fixture paths, or use --accept all after reviewing all changes.")
    baseline = json.loads(baseline_path.read_text()) if baseline_path.exists() else {"hashes": {}}
    if baseline.get("environment") != report["environment"] and chosen != changes:
        parser.error("A new compiler environment requires reviewing and accepting all changes together.")
    for name in chosen:
        value = report["hashes"].get(name)
        if value is not None and digest(review_dir / "pdfs" / f"{value}.pdf") != value:
            parser.error(f"Reviewed PDF is missing or modified: {name}. Run tools/test.py again.")
    for name in chosen:
        if name in report["hashes"]:
            baseline["hashes"][name] = report["hashes"][name]
        else:
            baseline["hashes"].pop(name, None)
    baseline["environment"] = report["environment"]
    write_json(baseline_path, baseline)
    # Consume the review so later acceptance always starts with a fresh run.
    report_path.unlink()
    print(f"Accepted {len(chosen)} reviewed PDF hashes. Run tools/test.py to verify the baseline.")
    return 0


def save_review(review_dir, baseline_sha256, baseline, environment, hashes, failures):
    previous = baseline.get("hashes", {})
    changed_environment = baseline.get("environment") != environment
    changes = {}
    for name in sorted(previous.keys() | hashes.keys()):
        before, after = previous.get(name), hashes.get(name)
        if before != after or changed_environment:
            changes[name] = {"before": before, "after": after}
    write_json(review_dir / "review.json", {
        "baseline_sha256": baseline_sha256, "environment": environment,
        "hashes": hashes, "changes": changes, "failures": failures,
    })
    lines = ["# PDF hash review", "", f"Compiler: `{environment['typst']}`", "",
             "Inspect each changed PDF before accepting its hash. A changed hash is not proof of a bug.", ""]
    if changed_environment:
        lines.extend(["The compiler environment changed or this is the first baseline. Review all outputs together.", ""])
    if failures:
        lines.extend(["This run has compilation or diagnostic failures. Acceptance is disabled; missing outputs may be failed tests, not removals.", ""])
    for name, values in changes.items():
        lines.extend([f"## {name}", ""])
        for label, value in values.items():
            if value is None:
                lines.append(f"- {label}: no PDF")
            elif (review_dir / "pdfs" / f"{value}.pdf").exists():
                lines.append(f"- [{label} PDF](pdfs/{value}.pdf), SHA-256 `{value}`")
            else:
                lines.append(f"- {label}: SHA-256 `{value}`; PDF not cached locally. Reproduce it from the baseline's Git revision using the same compiler environment.")
        lines.append("")
    (review_dir / "review.md").write_text("\n".join(lines) + "\n")
    return changes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--typst", default="typst", help="Typst executable")
    parser.add_argument("--timeout", type=float, default=120, help="Seconds per fixture")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--compile-only", action="store_true", help="Check compilation and diagnostics without PDF hashes")
    mode.add_argument("--accept", nargs="+", metavar="FIXTURE", help="Accept inspected PDFs from the last run: fixture paths or 'all'; does not compile")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    baseline_path = root / "tests/pdf-hashes.json"
    review_dir = root / "build/pdf-review"
    if args.accept:
        return accept_review(parser, baseline_path, review_dir, args.accept)
    compiler = shutil.which(args.typst)
    if compiler is None:
        parser.error(f"Typst executable not found: {args.typst}")
    environment = {
        "typst": subprocess.run([compiler, "--version"], capture_output=True, text=True, check=True).stdout.strip(),
        "creation_timestamp": "0", "fonts": "embedded-only",
    }
    env = os.environ.copy()
    env.pop("TYPST_FONT_PATHS", None)
    env.pop("TYPST_IGNORE_EMBEDDED_FONTS", None)
    env.pop("TYPST_FEATURES", None)
    baseline = json.loads(baseline_path.read_text()) if baseline_path.exists() else {}
    baseline_sha256 = digest(baseline_path)
    hashes = {}
    if not args.compile_only:
        (review_dir / "pdfs").mkdir(parents=True, exist_ok=True)
        # An interrupted run must not leave an older review eligible for acceptance.
        (review_dir / "review.json").unlink(missing_ok=True)
    expected = json.loads((root / "tests/errors/expected.json").read_text())
    errors = sorted((root / "tests/errors").glob("*.typ"))
    if set(expected) != {path.name for path in errors}:
        parser.error("tests/errors/expected.json must list every error fixture exactly once")
    fixtures = sorted((root / "tests").glob("*.typ")) + sorted((root / "examples").glob("*.typ")) + errors
    failures = 0
    with tempfile.TemporaryDirectory(prefix="math-once-tests-") as directory:
        work = Path(directory)
        package = tomllib.loads((root / "typst.toml").read_text())["package"]
        packages = work / "packages"
        local = packages / "local" / package["name"] / package["version"]
        local.mkdir(parents=True)
        # The distributed implementation is currently a single source file.
        for filename in (package["entrypoint"], "typst.toml"):
            shutil.copyfile(root / filename, local / filename)
        for fixture in fixtures:
            relative = fixture.relative_to(root)
            diagnostic = expected.get(fixture.name) if fixture.parent.name == "errors" else None
            try:
                result = subprocess.run(
                    [compiler, "compile", "--root", str(root), "--package-path", str(packages),
                     "--creation-timestamp", "0", "--ignore-system-fonts",
                     str(fixture), str(work / "fixture.pdf")],
                    capture_output=True, text=True, timeout=args.timeout, env=env,
                )
                passed = (result.returncode != 0 and diagnostic in result.stderr) if diagnostic else result.returncode == 0
                detail = result.stderr
            except subprocess.TimeoutExpired:
                passed, detail = False, f"Timed out after {args.timeout} seconds"
            outcome = "PASS" if passed else "FAIL"
            if passed and not diagnostic and not args.compile_only:
                value = digest(work / "fixture.pdf")
                hashes[relative.as_posix()] = value
                shutil.copyfile(work / "fixture.pdf", review_dir / "pdfs" / f"{value}.pdf")
                if baseline.get("hashes", {}).get(relative.as_posix()) != value or baseline.get("environment") != environment:
                    outcome = "REVIEW"
            print(f"{outcome} {relative}", flush=True)
            if not passed:
                failures += 1
                if diagnostic:
                    print(f"Expected compilation failure containing: {diagnostic}")
                print(detail or "Compilation unexpectedly succeeded")
    print(f"{len(fixtures) - failures}/{len(fixtures)} compilation and diagnostic checks passed")
    changes = {}
    if not args.compile_only:
        changes = save_review(review_dir, baseline_sha256, baseline, environment, hashes, failures)
        if changes:
            print(f"{len(changes)} PDF baselines require review: {review_dir / 'review.md'}")
            print("Inspect the PDFs, then accept selected fixture paths with: python3 tools/test.py --accept tests/example.typ")
    return 1 if failures or changes else 0


if __name__ == "__main__":
    sys.exit(main())
