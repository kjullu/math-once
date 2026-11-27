"""Fair baseline timing and independent timeout handling."""

import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("speed_test", Path(__file__).parents[1] / "speed-test.py")
speed = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(speed)


class PairedTimingTests(unittest.TestCase):
    def setUp(self):
        self.before = Path("before.typ")
        self.after = Path("after.typ")

    def test_alternates_order_and_reports_each_versions_median(self):
        values = {self.before: iter([9, 1, 5]), self.after: iter([7, 3, 2])}
        with patch.object(speed, "time_compile", side_effect=lambda _, __, source, ___: next(values[source])) as compile:
            result = speed.time_pair("typst", Path("."), self.before, self.after, 3, 30)
        self.assertEqual(result, (5, 3))
        self.assertEqual([call.args[2] for call in compile.call_args_list],
                         [self.before, self.after, self.after, self.before, self.before, self.after])

    def test_timeout_only_stops_the_affected_version(self):
        for timeout_source in (self.before, self.after):
            with self.subTest(source=timeout_source):
                calls = []

                def compile(_, __, source, ___):
                    calls.append(source)
                    return None if source == timeout_source else 2

                with patch.object(speed, "time_compile", side_effect=compile):
                    result = speed.time_pair("typst", Path("."), self.before, self.after, 3, 30)
                self.assertEqual(result, (None, 2) if timeout_source == self.before else (2, None))
                self.assertEqual(calls.count(timeout_source), 1)
                self.assertEqual(calls.count(self.after if timeout_source == self.before else self.before), 3)

    def test_compile_errors_remain_failures(self):
        with patch.object(speed, "time_compile", side_effect=RuntimeError("invalid document")):
            with self.assertRaisesRegex(RuntimeError, "invalid document"):
                speed.time_pair("typst", Path("."), self.before, self.after, 3, 30)


if __name__ == "__main__":
    unittest.main()
