"""Generate the agent views from the canonical standards corpus.

`standards/STANDARDS.chrysa.md` is the tool-agnostic single source of truth. Every
agent-facing view is *generated* from it, never hand-authored, so the same rules reach
every agent (Claude, AGENTS.md, GitHub Copilot) and the always-on context stays slim:

  * ``standards/rules/<domain>.md``    — the full detail, split by domain (load on demand;
                                         deliberately NOT under ``.claude/rules/``, which this
                                         repo auto-loads into every agent context — that would
                                         negate the token saving)
  * ``standards/CORE.chrysa.md``       — the slim always-on core (rule title + pointer),
                                         the body ``distribute-standards.sh`` inlines into
                                         every repo's ``CLAUDE.md`` managed block
  * this repo's ``CLAUDE.md`` block    — the same core, injected between the managed markers
  * ``AGENTS.md``                      — the same core, in a managed block
  * ``.github/copilot-instructions.md``— the same core, in a managed block

Rules are classified by domain through ``standards/rule-domains.yaml`` (a committed
side-mapping — the canon prose stays clean, no inline tags). A rule with no mapping entry
falls back to the ``general`` domain and is reported (never a hard failure), so adding a
rule to the canon always flows through to every view.

Run ``python -m scripts.gen_agent_views`` to (re)write the views, or
``python -m scripts.gen_agent_views --check`` to fail on drift (the ``agent-views-drift``
pre-commit hook + the CI gate). Deterministic output — stable ordering everywhere — so the
drift check is stable.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

_ROOT = Path(__file__).resolve().parent.parent
CANON = _ROOT / "standards" / "STANDARDS.chrysa.md"
MAPPING = _ROOT / "standards" / "rule-domains.yaml"

CORE = _ROOT / "standards" / "CORE.chrysa.md"
# On-demand detail lives here — NOT under .claude/rules/, which the repo auto-loads into
# every agent session (that would defeat the point of a slim always-on core).
RULES_DIR = _ROOT / "standards" / "rules"
RULES_REL = "standards/rules"
CLAUDE_MD = _ROOT / "CLAUDE.md"
AGENTS_MD = _ROOT / "AGENTS.md"
COPILOT_MD = _ROOT / ".github" / "copilot-instructions.md"

# The section whose flat bullets mix every domain and therefore need per-rule mapping.
MIXED_SECTION = "Non-negotiable conventions"
DEFAULT_DOMAIN = "general"

# CLAUDE.md managed-block markers — identical to distribute-standards.sh, so the block this
# generator injects locally is byte-for-byte what the fleet distribution would inline.
CLAUDE_MARK_START = (
    "<!-- chrysa:standards:start · managed by distribute-standards.sh · DO NOT EDIT -->"
)
CLAUDE_MARK_END = "<!-- chrysa:standards:end -->"
# Per-view managed markers for the append-in-place views.
AGENTS_MARK_START = "<!-- chrysa:standards-agents:start · generated · DO NOT EDIT -->"
AGENTS_MARK_END = "<!-- chrysa:standards-agents:end -->"
COPILOT_MARK_START = "<!-- chrysa:standards-copilot:start · generated · DO NOT EDIT -->"
COPILOT_MARK_END = "<!-- chrysa:standards-copilot:end -->"

_GEN_HEADER = (
    "<!-- GENERATED from standards/STANDARDS.chrysa.md by scripts/gen_agent_views.py — "
    "do not edit.\n"
    "Canonical source of truth is the canon; edit there, then run "
    "`make gen-agent-views` to regenerate every view.\n"
    "-->"
)
_BOLD = re.compile(r"\*\*(.+?)\*\*", re.DOTALL)


@dataclass
class Rule:
    """One classified unit of the canon: a single mixed-section bullet, or a whole section."""

    domain: str
    title: str
    body: str
    order: int
    is_section: bool = False


@dataclass
class Section:
    title: str
    body: list[str] = field(default_factory=list)


# --------------------------------------------------------------------------- parsing


def _split_sections(text: str) -> tuple[list[str], list[Section]]:
    """Return (preamble_lines_before_first_H2, [Section, ...])."""
    preamble: list[str] = []
    sections: list[Section] = []
    current: Section | None = None
    for line in text.splitlines():
        match = re.match(r"^## (.+)$", line)
        if match:
            current = Section(title=match.group(1).strip())
            sections.append(current)
        elif current is None:
            preamble.append(line)
        else:
            current.body.append(line)
    return preamble, sections


def _split_rule_blocks(body: list[str]) -> list[list[str]]:
    """Split a section body into top-level ``- **`` bullet blocks (code-fence aware)."""
    blocks: list[list[str]] = []
    current: list[str] = []
    in_fence = False
    for line in body:
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
        if not in_fence and re.match(r"^- \*\*", line):
            if current:
                blocks.append(current)
            current = [line]
        elif current:
            current.append(line)
    if current:
        blocks.append(current)
    return blocks


def _rule_title(block_text: str) -> str:
    """The first bold span of a bullet, whitespace-collapsed, trailing period stripped."""
    match = _BOLD.search(block_text)
    raw = match.group(1) if match else block_text.lstrip("- ").splitlines()[0]
    return re.sub(r"\s+", " ", raw).strip().rstrip(".").strip()


# ------------------------------------------------------------------------ classify


def _load_mapping() -> tuple[dict[str, str], dict[str, str], dict[str, str]]:
    """Return (rule_title→domain, section_title→domain, domain_id→label).

    Ordering is never taken from this file — it is yaml-sorted by the repo's hook, so
    domain order is derived from the canon (first appearance) and rule order from the
    canon too. This mapping carries classification only.
    """
    data = yaml.safe_load(MAPPING.read_text(encoding="utf-8"))
    rules = {str(k): str(v) for k, v in (data.get("rules") or {}).items()}
    sections = {str(k): str(v) for k, v in (data.get("sections") or {}).items()}
    labels = {str(k): str(v) for k, v in (data.get("domains") or {}).items()}
    return rules, sections, labels


def parse_rules() -> tuple[list[Rule], list[str]]:
    """Parse the canon into classified rules. Returns (rules, warnings)."""
    text = CANON.read_text(encoding="utf-8")
    _, sections = _split_sections(text)
    rule_map, section_map, _ = _load_mapping()
    rules: list[Rule] = []
    warnings: list[str] = []
    order = 0
    for section in sections:
        if section.title == MIXED_SECTION:
            for block in _split_rule_blocks(section.body):
                block_text = "\n".join(block).rstrip()
                title = _rule_title(block_text)
                domain = rule_map.get(title)
                if domain is None:
                    domain = DEFAULT_DOMAIN
                    warnings.append(f"unmapped rule → {DEFAULT_DOMAIN!r}: {title}")
                rules.append(Rule(domain=domain, title=title, body=block_text, order=order))
                order += 1
        else:
            domain = section_map.get(section.title)
            if domain is None:
                domain = DEFAULT_DOMAIN
                warnings.append(f"unmapped section → {DEFAULT_DOMAIN!r}: {section.title}")
            body = "\n".join(section.body).strip()
            rules.append(
                Rule(domain=domain, title=section.title, body=body, order=order, is_section=True)
            )
            order += 1
    return rules, warnings


def _domain_order(rules: list[Rule]) -> list[str]:
    """Domains in canon order — first appearance of a rule assigned to them."""
    seen: list[str] = []
    for rule in sorted(rules, key=lambda r: r.order):
        if rule.domain not in seen:
            seen.append(rule.domain)
    return seen


def _label(domain: str) -> str:
    _, _, labels = _load_mapping()
    return labels.get(domain, domain.replace("-", " ").title())


# -------------------------------------------------------------------------- render


def _rule_index() -> list[str]:
    """The slim rule index shared byte-for-byte by the core, AGENTS and copilot views."""
    rules, _ = parse_rules()
    lines: list[str] = []
    for domain in _domain_order(rules):
        members = sorted((r for r in rules if r.domain == domain), key=lambda r: r.order)
        lines.append(f"### {_label(domain)} · `{RULES_REL}/{domain}.md`")
        lines.extend(f"- {rule.title}" for rule in members)
        lines.append("")
    return lines


def _domain_file(domain: str, rules: list[Rule]) -> str:
    members = sorted((r for r in rules if r.domain == domain), key=lambda r: r.order)
    out = [
        _GEN_HEADER,
        f"# {_label(domain)}",
        "",
        "> Detail for the slim core in `CLAUDE.md`. **Generated** from "
        "`standards/STANDARDS.chrysa.md` — do not edit here; edit the canon and regenerate.",
        "",
    ]
    for rule in members:
        if rule.is_section:
            out.append(f"## {rule.title}")
            out.append("")
            out.append(rule.body)
        else:
            out.append(rule.body)
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def _core_text() -> str:
    out = [
        _GEN_HEADER,
        "# chrysa — Transverse Standards (core)",
        "",
        "> The **slim always-on core**. The canonical, tool-agnostic source of truth is "
        "`standards/STANDARDS.chrysa.md`; the normative annexes live under "
        "`standards/annexes/`. Each rule below is a one-line pointer — its full text lives "
        "in the per-domain file named beside the heading (`standards/rules/<domain>.md`), "
        "read on demand.",
        "",
        "**Where an annexe and the canon disagree, the canon wins.**",
        "",
    ]
    out.extend(_rule_index())
    return "\n".join(out).rstrip() + "\n"


def _strip_gen_header(core_text: str) -> str:
    """Drop the leading HTML header comment (through the ``-->`` line) + leading blanks.

    Mirrors ``build_block`` in ``distribute-standards.sh`` so the block injected here is
    byte-identical to what the fleet distribution inlines from ``CORE.chrysa.md``.
    """
    lines = core_text.splitlines()
    start = 0
    for index, line in enumerate(lines):
        if line.startswith("-->"):
            start = index + 1
            break
    while start < len(lines) and not lines[start].strip():
        start += 1
    return "\n".join(lines[start:]).rstrip() + "\n"


def _managed_block(start: str, end: str, body: str) -> str:
    return f"{start}\n{body.rstrip()}\n{end}"


def _inject(text: str, start: str, end: str, block_body: str) -> str:
    """Replace (or append) the ``start..end`` managed block inside ``text``."""
    block = _managed_block(start, end, block_body)
    if start in text and end in text:
        pattern = re.compile(re.escape(start) + r".*?" + re.escape(end), re.DOTALL)
        return pattern.sub(lambda _m: block, text, count=1)
    sep = "" if text.endswith("\n\n") else ("\n" if text.endswith("\n") else "\n\n")
    return f"{text}{sep}{block}\n"


# ------------------------------------------------------------------------- outputs


def _agents_view() -> str:
    body = [
        "# chrysa standards — agent view (generated)",
        "",
        "> The same rules as `CLAUDE.md`, for any AGENTS.md-aware tool. Detail loads on "
        "demand from `standards/rules/<domain>.md`; the canon is "
        "`standards/STANDARDS.chrysa.md`.",
        "",
    ]
    body.extend(_rule_index())
    return "\n".join(body).rstrip() + "\n"


def _copilot_view() -> str:
    body = [
        "## chrysa standards (generated)",
        "",
        "> The same rules as `CLAUDE.md`, for GitHub Copilot. Detail loads on demand from "
        "`standards/rules/<domain>.md`; the canon is `standards/STANDARDS.chrysa.md`.",
        "",
    ]
    body.extend(_rule_index())
    return "\n".join(body).rstrip() + "\n"


def _planned_outputs() -> dict[Path, str]:
    """Every file this generator owns, mapped to its expected content."""
    rules, _ = parse_rules()
    outputs: dict[Path, str] = {}
    for domain in _domain_order(rules):
        outputs[RULES_DIR / f"{domain}.md"] = _domain_file(domain, rules)
    outputs[CORE] = _core_text()

    core_body = _strip_gen_header(_core_text())
    outputs[CLAUDE_MD] = _inject(
        CLAUDE_MD.read_text(encoding="utf-8"),
        CLAUDE_MARK_START,
        CLAUDE_MARK_END,
        core_body,
    )
    outputs[AGENTS_MD] = _inject(
        AGENTS_MD.read_text(encoding="utf-8"),
        AGENTS_MARK_START,
        AGENTS_MARK_END,
        _agents_view(),
    )
    outputs[COPILOT_MD] = _inject(
        COPILOT_MD.read_text(encoding="utf-8"),
        COPILOT_MARK_START,
        COPILOT_MARK_END,
        _copilot_view(),
    )
    return outputs


def _stale_domain_files(planned: dict[Path, str]) -> list[Path]:
    """Generated ``.claude/rules/*.md`` that no longer correspond to a domain."""
    owned = {p for p in planned if p.parent == RULES_DIR}
    stale: list[Path] = []
    for existing in sorted(RULES_DIR.glob("*.md")):
        if existing in owned:
            continue
        head = existing.read_text(encoding="utf-8")[:200]
        if "GENERATED from standards/STANDARDS.chrysa.md" in head:
            stale.append(existing)
    return stale


def write() -> list[str]:
    """Write every view. Returns the list of parse warnings."""
    _, warnings = parse_rules()
    RULES_DIR.mkdir(parents=True, exist_ok=True)
    planned = _planned_outputs()
    for path, content in planned.items():
        path.write_text(content, encoding="utf-8")
    for stale in _stale_domain_files(planned):
        stale.unlink()
    return warnings


def check() -> list[str]:
    """Return a list of drift lines (empty when every view is current)."""
    planned = _planned_outputs()
    problems: list[str] = []
    for path, content in planned.items():
        rel = path.relative_to(_ROOT)
        if not path.exists():
            problems.append(f"missing: {rel}")
        elif path.read_text(encoding="utf-8") != content:
            problems.append(f"stale: {rel}")
    problems.extend(
        f"orphaned generated rule file: {stale.relative_to(_ROOT)}"
        for stale in _stale_domain_files(planned)
    )
    return problems


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if "--check" in args:
        problems = check()
        if not problems:
            return 0
        sys.stderr.write("agent views have drifted from the canon:\n")
        for line in problems:
            sys.stderr.write(f"  - {line}\n")
        sys.stderr.write(
            "Regenerate with `make gen-agent-views` "
            "(or `python -m scripts.gen_agent_views`) and commit the result.\n"
        )
        return 1
    warnings = write()
    for line in warnings:
        sys.stderr.write(f"  warning: {line}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
