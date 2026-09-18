#!/usr/bin/env python3
"""Compile all fixtures and examples without leaving generated files in the repo."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--typst", default="typst", help="Typst executable")
    parser.add_argument("--timeout", type=float, default=120, help="Seconds per fixture")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    compiler = shutil.which(args.typst)
    if compiler is None:
        parser.error(f"Typst executable not found: {args.typst}")
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
                     str(fixture), str(work / "fixture.pdf")],
                    capture_output=True, text=True, timeout=args.timeout,
                )
                passed = (result.returncode != 0 and diagnostic in result.stderr) if diagnostic else result.returncode == 0
                detail = result.stderr
            except subprocess.TimeoutExpired:
                passed, detail = False, f"Timed out after {args.timeout} seconds"
            print(f"{'PASS' if passed else 'FAIL'} {relative}", flush=True)
            if not passed:
                failures += 1
                if diagnostic:
                    print(f"Expected compilation failure containing: {diagnostic}")
                print(detail or "Compilation unexpectedly succeeded")
    print(f"{len(fixtures) - failures}/{len(fixtures)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
