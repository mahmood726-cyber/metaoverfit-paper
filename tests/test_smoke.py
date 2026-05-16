import shutil
import subprocess
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def _find_rscript():
    candidates = [
        shutil.which("Rscript"),
        "/mnt/c/Program Files/R/R-4.5.2/bin/Rscript.exe",
        "/mnt/c/Program Files/R/R-4.5.2/bin/x64/Rscript.exe",
        "/mnt/c/Program Files/R/R-4.5.1/bin/Rscript.exe",
        "/mnt/c/Program Files/R/R-4.5.1/bin/x64/Rscript.exe",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return candidate
    return None


def test_core_package_files_exist():
    required = [
        ROOT / "DESCRIPTION",
        ROOT / "NAMESPACE",
        ROOT / "README.md",
        ROOT / "R" / "metaoverfit.R",
        ROOT / "tests" / "testthat.R",
        ROOT / "tests" / "testthat" / "test-core.R",
        ROOT / "PLOS_ONE_Manuscript.md",
        ROOT / "e156-submission" / "index.html",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.exists()]
    assert not missing, f"Missing required metaoverfit files: {missing}"


def test_description_and_namespace_contract():
    description = (ROOT / "DESCRIPTION").read_text(encoding="utf-8")
    namespace = (ROOT / "NAMESPACE").read_text(encoding="utf-8")

    assert "Package: metaoverfit" in description
    assert "License: GPL-3" in description
    for export in [
        "export(calculate_r2het)",
        "export(check_overfitting)",
        "export(r2het_boot)",
        "export(r2het_cv)",
        "export(sample_size_recommendation)",
    ]:
        assert export in namespace


def test_r_test_suite_is_present_and_named():
    testthat_entry = (ROOT / "tests" / "testthat.R").read_text(encoding="utf-8")
    test_file = (ROOT / "tests" / "testthat" / "test-core.R").read_text(
        encoding="utf-8"
    )

    assert 'test_check("metaoverfit")' in testthat_entry
    assert "calculate_r2het works correctly" in test_file
    assert "r2het_cv works with simulated numeric data" in test_file


def test_r_test_suite_runs_when_rscript_is_available():
    rscript = _find_rscript()
    if not rscript:
        pytest.skip("Rscript is not installed in this environment")

    result = subprocess.run(
        [rscript, "--vanilla", "-e", "testthat::test_local('.')"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout

