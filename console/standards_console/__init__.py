"""Local management console for the chrysa shared standards fleet.

A thin GitHub-API-backed console: it holds almost no local state. The fleet,
``repos.yml``, the canonical standard, workflow runs and PRs are all read live
from GitHub; writes go back through the GitHub API. Compliance data is read
from the hosted guideline-checker central server when configured.
"""

__version__ = "0.1.0"
