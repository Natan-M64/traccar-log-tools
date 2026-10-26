import importlib.util
import os
import tempfile
import unittest
from pathlib import Path

os.environ.setdefault("API_PORT", "8080")

MODULE_PATH = Path(__file__).with_name("api_server.py")
SPEC = importlib.util.spec_from_file_location("api_server", MODULE_PATH)
api_server = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(api_server)


class ValidateImeiTests(unittest.TestCase):
    def test_accepts_numeric_imei_with_supported_length(self):
        self.assertTrue(api_server.validate_imei("12345678"))
        self.assertTrue(api_server.validate_imei("12345678901234567890"))

    def test_rejects_invalid_imei(self):
        for value in (None, "", "1234567", "123456789012345678901", "1234abc5678"):
            with self.subTest(value=value):
                self.assertFalse(api_server.validate_imei(value))


class ParseLimitTests(unittest.TestCase):
    def setUp(self):
        self.original_max_lines = api_server.MAX_LINES
        api_server.MAX_LINES = 2000

    def tearDown(self):
        api_server.MAX_LINES = self.original_max_lines

    def test_uses_default_for_missing_or_invalid_limit(self):
        self.assertEqual(api_server.parse_limit({}), 300)
        self.assertEqual(api_server.parse_limit({"limit": ["invalid"]}), 300)

    def test_clamps_limit_to_supported_range(self):
        self.assertEqual(api_server.parse_limit({"limit": ["0"]}), 1)
        self.assertEqual(api_server.parse_limit({"limit": ["5000"]}), 2000)


class ReadMatchingLinesTests(unittest.TestCase):
    def setUp(self):
        self.original_log_file = api_server.LOG_FILE

    def tearDown(self):
        api_server.LOG_FILE = self.original_log_file

    def test_returns_only_latest_matching_lines(self):
        with tempfile.TemporaryDirectory() as directory:
            log_path = Path(directory) / "tracker-server.log"
            log_path.write_text(
                "first 123456789012345\n"
                "ignored 999999999999999\n"
                "second 123456789012345\n"
                "third 123456789012345\n",
                encoding="utf-8",
            )
            api_server.LOG_FILE = log_path

            self.assertEqual(
                api_server.read_matching_lines("123456789012345", 2),
                ["second 123456789012345", "third 123456789012345"],
            )


if __name__ == "__main__":
    unittest.main()
