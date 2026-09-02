"""Tests for the agent-view generator (scripts/gen_agent_views.py).

Two guarantees are load-bearing and therefore asserted here:

  * **Multi-agent** — a rule added to the canon flows through to *every* view (the slim
    core, the AGENTS view, the Copilot view, and its per-domain detail file). This is the
    property that keeps one source → N views honest.
  * **Idempotent + drift-free** — the committed views equal what the generator produces from
    the current canon (``check()`` is empty), and generation is a fixed point.
"""

from __future__ import annotations

import textwrap
from pathlib import Path

from scripts import gen_agent_views as g

MIN_CANON = """\
<!-- header -->
-->

# chrysa — Transverse Standards

## Non-negotiable conventions

- **An existing mapped rule** — body of the first rule.

- **A brand new canon rule for the test** — body of the injected rule that must reach
  every generated view.

## Design system

- **Some design token rule** — body.
"""

MIN_MAPPING = """\
version: 1
domains:
  testing: Testing
  design: Design system
  general: General
sections:
  Design system: design
rules:
  An existing mapped rule: testing
  A brand new canon rule for the test: testing
"""


def _point_at_tmp(monkeypatch, tmp_path: Path, canon: str, mapping: str) -> None:
    canon_path = tmp_path / "STANDARDS.chrysa.md"
    mapping_path = tmp_path / "rule-domains.yaml"
    canon_path.write_text(canon, encoding="utf-8")
    mapping_path.write_text(mapping, encoding="utf-8")
    monkeypatch.setattr(g, "CANON", canon_path)
    monkeypatch.setattr(g, "MAPPING", mapping_path)


class TestMultiAgentGuarantee:
    def test_new_rule_reaches_all_four_views(self, monkeypatch, tmp_path):
        _point_at_tmp(monkeypatch, tmp_path, MIN_CANON, MIN_MAPPING)
        new_title = "A brand new canon rule for the test"

        rules, warnings = g.parse_rules()
        assert warnings == []
        assert any(r.title == new_title and r.domain == "testing" for r in rules)

        core = g._core_text()
        agents = g._agents_view()
        copilot = g._copilot_view()
        domain_file = g._domain_file("testing", rules)

        # View 1-3: the slim renderings each list the new rule's title.
        for view in (core, agents, copilot):
            assert new_title in view
        # View 4: the per-domain detail file carries the rule's body verbatim.
        assert "body of the injected rule" in domain_file

    def test_unmapped_rule_falls_back_to_general_and_is_reported(self, monkeypatch, tmp_path):
        mapping = MIN_MAPPING.replace(
            "  A brand new canon rule for the test: testing\n", ""
        )
        _point_at_tmp(monkeypatch, tmp_path, MIN_CANON, mapping)

        rules, warnings = g.parse_rules()
        injected = next(
            r for r in rules if r.title == "A brand new canon rule for the test"
        )
        assert injected.domain == g.DEFAULT_DOMAIN
        assert any("A brand new canon rule for the test" in w for w in warnings)


class TestParsing:
    def test_multiline_bold_title_is_collapsed(self, monkeypatch, tmp_path):
        canon = textwrap.dedent(
            """\
            <!-- h -->
            -->

            ## Non-negotiable conventions

            - **A title that wraps
              across two lines** — the body.
            """
        )
        mapping = "version: 1\ndomains: {general: General}\nsections: {}\nrules: {}\n"
        _point_at_tmp(monkeypatch, tmp_path, canon, mapping)
        rules, _ = g.parse_rules()
        assert rules[0].title == "A title that wraps across two lines"

    def test_rule_blocks_are_fence_aware(self, monkeypatch, tmp_path):
        canon = textwrap.dedent(
            """\
            <!-- h -->
            -->

            ## Non-negotiable conventions

            - **Only rule** — has a fenced block.
              ```yaml
              - **not a rule** inside a fence
              ```
            """
        )
        mapping = "version: 1\ndomains: {general: General}\nsections: {}\nrules: {}\n"
        _point_at_tmp(monkeypatch, tmp_path, canon, mapping)
        rules, _ = g.parse_rules()
        assert len(rules) == 1


class TestCommittedViewsAreCurrent:
    def test_check_is_clean(self):
        # Guards the whole repo: the committed views equal what the generator produces from
        # the current canon + mapping. Fails exactly when someone edits the canon and forgets
        # `make gen-agent-views` — the same signal as the pre-commit/CI drift gate.
        assert g.check() == []

    def test_every_canon_rule_is_mapped(self):
        _, warnings = g.parse_rules()
        assert warnings == [], f"unmapped rules/sections in the canon: {warnings}"

    def test_generation_is_idempotent(self):
        # Building the planned outputs twice yields identical bytes for every view.
        first = {p: c for p, c in g._planned_outputs().items()}
        second = {p: c for p, c in g._planned_outputs().items()}
        assert first == second

    def test_emit_matches_the_committed_blocks(self, capsys):
        # `--emit` is what distribute-standards.sh consumes to deliver each view to a
        # consumer repo. Its body must equal the block the generator injects locally, so
        # the fleet gets byte-identical content without re-rendering the canon in bash.
        core_body = g._strip_gen_header(g._core_text())
        assert g.emit("claude") == core_body
        assert g.emit("agents") == g._agents_view()
        assert g.emit("copilot") == g._copilot_view()

        for view, expected in (
            ("claude", core_body),
            ("agents", g._agents_view()),
            ("copilot", g._copilot_view()),
        ):
            assert g.main(["--emit", view]) == 0
            assert capsys.readouterr().out == expected

    def test_emit_rejects_an_unknown_view(self, capsys):
        assert g.main(["--emit", "nope"]) == 2
        assert g.main(["--emit"]) == 2
        assert "usage:" in capsys.readouterr().err
