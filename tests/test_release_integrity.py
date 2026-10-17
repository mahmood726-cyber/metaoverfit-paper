"""No unsupported publication status in package metadata."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReleaseIntegrity(unittest.TestCase):
    def test_not_forthcoming_without_acceptance(self):
        for path in ("README.md", "inst/CITATION"):
            text = (ROOT / path).read_text(encoding="utf-8")
            self.assertNotIn("forthcoming", text.lower())
        self.assertIn('bibtype = "Manual"', (ROOT / "inst/CITATION").read_text())

    def test_install_and_issue_paths_match_actual_package(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        description = (ROOT / "DESCRIPTION").read_text(encoding="utf-8")
        self.assertIn('remotes::install_github("mahmood726-cyber/metaoverfit-paper")', readme)
        self.assertIn("URL: https://github.com/mahmood726-cyber/metaoverfit-paper", description)
        self.assertIn("BugReports: https://github.com/mahmood726-cyber/metaoverfit-paper/issues", description)


if __name__ == "__main__":
    unittest.main()
