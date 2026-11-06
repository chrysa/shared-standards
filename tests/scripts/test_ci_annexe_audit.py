"""Regression tests for the annexe CI fixer (scripts/ci_annexe_audit.py).

Two fleet incidents are locked in here:

* the CI-030 rebuild dropped every top-level key written after `jobs:`. On a key-sorted
  workflow that is `name:`, `on:` and `permissions:`, so the patched workflows of
  genealogy-validator, audit-platform and chrysa-lib lost their triggers;
* the CI-031 rule added `${{ github.workflow }}-${{ github.ref }}` to workflows that only
  call a chrysa/github-actions workflow, which declares the same group: GitHub then cancels
  every run ("Canceling since a deadlock was detected for concurrency group").
"""

from __future__ import annotations

import re

from scripts.ci_annexe_audit import fix, inspect

KEY_SORTED = """concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  labels:
    name: Apply labels
    runs-on: ubuntu-latest
    steps:
    - uses: actions/labeler@bf12e9b00b37c5c0ca2b87b79b2daf7891dbda13
name: Pull Request Labels
'on':
  pull_request: null
permissions:
  contents: read
  pull-requests: write
"""

CALLER_ONLY = """name: pre-commit
on:
  pull_request:
    branches: [develop]
jobs:
  call:
    uses: chrysa/github-actions/.github/workflows/pre-commit.yml@v1.10.0
permissions:
  contents: read
"""

PLAIN = """name: Lint
on:
  pull_request:
permissions:
  contents: read
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: echo lint
"""


def test_fix_keeps_top_level_keys_after_jobs() -> None:
    patched = fix(KEY_SORTED, "labeler.yml")
    assert patched is not None
    assert "timeout-minutes: 30" in patched
    for key in ("name: Pull Request Labels", "'on':", "permissions:"):
        assert key in patched
    assert patched.endswith("  pull-requests: write\n")


def test_caller_only_workflow_gets_no_concurrency_group() -> None:
    assert "CI-031" not in inspect(CALLER_ONLY, "pre-commit.yml")
    assert fix(CALLER_ONLY, "pre-commit.yml") is None


def test_plain_pr_workflow_still_gets_concurrency_and_timeout() -> None:
    assert {"CI-030", "CI-031"} <= set(inspect(PLAIN, "lint.yml"))
    patched = fix(PLAIN, "lint.yml")
    assert patched is not None
    assert re.search(r"^concurrency:\n  group: ", patched, re.M)
    assert "timeout-minutes: 30" in patched
    assert len(re.findall(r"^on:", patched, re.M)) == 1
