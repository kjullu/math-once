"""Keep timeout reports useful even when a reference compile cannot finish."""

from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location("speed_test", Path(__file__).resolve().parents[1] / "speed-test.py")
speed = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(speed)


class SpeedTimeoutTests(unittest.TestCase):
    def test_timeout_at_each_measurement_retains_report(self):
        # Empty, import-only, plain, and math-once all have distinct reporting paths.
        for position in range(4):
            for limit in ([], ["--max-seconds", "7.5"]):
                with self.subTest(position=position, limit=limit), tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    (root / "tools").mkdir()
                    summary = root / "summary.md"
                    measurements = [0.1, 0.2, 0.3, 0.4]
                    measurements[position] = None
                    args = ["speed-test.py", "--sections", "1", "--runs", "1", "--summary", str(summary), *limit]
                    with patch.object(speed, "__file__", str(root / "tools/speed-test.py")), \
                         patch("sys.argv", args), \
                         patch.object(speed.shutil, "which", return_value="typst"), \
                         patch.object(speed.subprocess, "check_output", return_value="typst test"), \
                         patch.object(speed, "time_compile", side_effect=measurements), \
                         redirect_stdout(io.StringIO()):
                        self.assertEqual(speed.main(), 1)
                    results = json.loads((root / "build/speed-test/results.json").read_text())
                    self.assertEqual(len(results["documents"]), 1)
                    report = summary.read_text()
                    self.assertIn("timeout", report)
                    self.assertNotIn("Every document compiled", report)
                    if position < 3:
                        self.assertIn("Incomplete", report)
                    else:
                        self.assertIn("Too slow", report)


if __name__ == "__main__":
    unittest.main()
