"""Exercise the review/accept CLI in an isolated package with a fake compiler."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class ReviewWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in ("tools", "tests/errors", "examples"):
            (self.root / name).mkdir(parents=True)
        shutil.copyfile(Path(__file__).resolve().parents[1] / "test.py", self.root / "tools/test.py")
        (self.root / "typst.toml").write_text('[package]\nname = "demo"\nversion = "1.0.0"\nentrypoint = "math-once.typ"\n')
        (self.root / "math-once.typ").write_text("package")
        (self.root / "tests/a.typ").write_text("test output")
        (self.root / "examples/a.typ").write_text("example output")
        (self.root / "tests/errors/bad.typ").write_text("ERROR")
        (self.root / "tests/errors/expected.json").write_text(json.dumps({"bad.typ": "expected diagnostic"}))
        self.compiler = self.root / "typst"
        self.compiler.write_text(f"#!{sys.executable}\n" + '''
import os
from pathlib import Path
import sys
import time
if sys.argv[1] == "--version":
    print(os.environ.get("TEST_TYPST_VERSION", "typst test-1"))
    sys.exit(0)
assert "--ignore-system-fonts" in sys.argv
assert sys.argv[sys.argv.index("--creation-timestamp") + 1] == "0"
assert "TYPST_FONT_PATHS" not in os.environ
assert "TYPST_IGNORE_EMBEDDED_FONTS" not in os.environ
assert "TYPST_FEATURES" not in os.environ
packages = Path(sys.argv[sys.argv.index("--package-path") + 1])
assert (packages / "local/demo/1.0.0/math-once.typ").exists()
source = Path(sys.argv[-2]).read_text()
if source == "TIMEOUT":
    time.sleep(10)
if source in ("ERROR", "WRONG_ERROR"):
    print("expected diagnostic" if source == "ERROR" else "different error", file=sys.stderr)
    sys.exit(1)
Path(sys.argv[-1]).write_bytes(b"%PDF-fake\\n" + source.encode())
''')
        self.compiler.chmod(0o755)

    def run_cli(self, *args, expected=0, version="typst test-1"):
        env = dict(os.environ, TEST_TYPST_VERSION=version, TYPST_FONT_PATHS="unwanted-fonts",
                   TYPST_IGNORE_EMBEDDED_FONTS="true", TYPST_FEATURES="html")
        result = subprocess.run(
            [sys.executable, str(self.root / "tools/test.py"), "--typst", str(self.compiler), *args],
            cwd=self.root, capture_output=True, text=True, env=env, timeout=20,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def read_json(self, name):
        return json.loads((self.root / name).read_text())

    def seed(self):
        self.run_cli(expected=1)
        self.run_cli("--accept", "all")
        self.run_cli()

    def test_initial_baseline_repeat_and_selective_acceptance(self):
        self.run_cli(expected=1)
        self.assertFalse((self.root / "tests/pdf-hashes.json").exists())
        self.run_cli("--accept", "tests/a.typ", expected=2)
        self.run_cli("--accept", "all")
        baseline = (self.root / "tests/pdf-hashes.json").read_bytes()
        self.run_cli()
        self.assertEqual(baseline, (self.root / "tests/pdf-hashes.json").read_bytes())
        self.assertEqual(set(self.read_json("tests/pdf-hashes.json")["hashes"]), {"tests/a.typ", "examples/a.typ"})
        (self.root / "tests/a.typ").write_text("changed test")
        (self.root / "examples/a.typ").write_text("changed example")
        self.run_cli(expected=1)
        report = self.read_json("build/pdf-review/review.json")
        for pair in report["changes"].values():
            for value in pair.values():
                self.assertTrue((self.root / f"build/pdf-review/pdfs/{value}.pdf").exists())
        self.assertEqual(baseline, (self.root / "tests/pdf-hashes.json").read_bytes())
        self.run_cli("--accept", "tests/a.typ")
        self.run_cli("--accept", "examples/a.typ", expected=2)
        self.run_cli(expected=1)
        self.assertEqual(set(self.read_json("build/pdf-review/review.json")["changes"]), {"examples/a.typ"})
        self.run_cli("--accept", "examples/a.typ")
        self.run_cli()

    def test_new_and_removed_fixtures(self):
        self.seed()
        (self.root / "tests/a.typ").unlink()
        (self.root / "tests/new.typ").write_text("new output")
        self.run_cli(expected=1)
        report = self.read_json("build/pdf-review/review.json")
        self.assertIsNone(report["changes"]["tests/a.typ"]["after"])
        self.assertIsNone(report["changes"]["tests/new.typ"]["before"])
        self.run_cli("--accept", "all")
        self.run_cli()

    def test_failed_compilation_diagnostic_and_timeout_cannot_be_accepted(self):
        self.seed()
        baseline = (self.root / "tests/pdf-hashes.json").read_bytes()
        for name, source, args in (
            ("tests/a.typ", "ERROR", ()),
            ("tests/a.typ", "TIMEOUT", ("--timeout", "0.2")),
            ("tests/errors/bad.typ", "WRONG_ERROR", ()),
            ("tests/errors/bad.typ", "unexpected success", ()),
        ):
            with self.subTest(source=source):
                path = self.root / name
                old = path.read_text()
                path.write_text(source)
                self.run_cli(*args, expected=1)
                self.run_cli("--accept", "all", expected=2)
                self.assertEqual(baseline, (self.root / "tests/pdf-hashes.json").read_bytes())
                path.write_text(old)

    def test_stale_baseline_and_tampered_pdf_are_rejected(self):
        self.seed()
        (self.root / "tests/a.typ").write_text("changed")
        self.run_cli(expected=1)
        baseline = self.root / "tests/pdf-hashes.json"
        baseline.write_text(baseline.read_text() + "\n")
        self.run_cli("--accept", "all", expected=2)
        self.run_cli(expected=1)
        value = self.read_json("build/pdf-review/review.json")["hashes"]["tests/a.typ"]
        (self.root / f"build/pdf-review/pdfs/{value}.pdf").write_text("tampered")
        self.run_cli("--accept", "all", expected=2)

    def test_compiler_change_and_compile_only(self):
        self.seed()
        report = (self.root / "build/pdf-review/review.json").read_bytes()
        baseline = (self.root / "tests/pdf-hashes.json").read_bytes()
        self.run_cli("--compile-only", version="typst test-2")
        self.assertEqual(report, (self.root / "build/pdf-review/review.json").read_bytes())
        self.assertEqual(baseline, (self.root / "tests/pdf-hashes.json").read_bytes())
        self.run_cli(version="typst test-2", expected=1)
        self.run_cli("--accept", "tests/a.typ", expected=2)
        self.run_cli("--accept", "all")
        self.run_cli(version="typst test-2")

    def test_source_changed_after_review_is_not_silently_accepted(self):
        self.seed()
        (self.root / "tests/a.typ").write_text("reviewed output")
        self.run_cli(expected=1)
        reviewed = self.read_json("build/pdf-review/review.json")["hashes"]["tests/a.typ"]
        (self.root / "tests/a.typ").write_text("unreviewed output")
        self.run_cli("--accept", "all")
        self.assertEqual(self.read_json("tests/pdf-hashes.json")["hashes"]["tests/a.typ"], reviewed)
        self.run_cli(expected=1)

    @unittest.skipUnless(shutil.which("typst"), "Typst is required for the real PDF smoke test")
    def test_real_pdf_change_and_repeatability(self):
        self.compiler = Path(shutil.which("typst"))
        (self.root / "tests/errors/bad.typ").write_text('#panic("expected diagnostic")')
        (self.root / "tests/a.typ").write_text('#assert(2 + 2 == 4)\n$ x = 4 $')
        self.seed()
        (self.root / "tests/a.typ").write_text('#assert(2 + 2 == 4)\n$ x = 5 $')
        self.run_cli(expected=1)
        report = self.read_json("build/pdf-review/review.json")
        self.assertEqual(set(report["changes"]), {"tests/a.typ"})
        pair = report["changes"]["tests/a.typ"]
        self.assertNotEqual(pair["before"], pair["after"])
        for value in pair.values():
            self.assertTrue((self.root / f"build/pdf-review/pdfs/{value}.pdf").read_bytes().startswith(b"%PDF-"))
        self.run_cli("--accept", "tests/a.typ")
        self.run_cli()


if __name__ == "__main__":
    unittest.main()
