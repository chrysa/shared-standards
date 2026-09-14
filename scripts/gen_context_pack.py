#!/usr/bin/env python3
"""Generate a portable, vendor-neutral AI context pack for a repository.

Produces (per repo), preserving any manual sections on regeneration:
  - passation.md          handover: state, place in the ecosystem, dependencies, ADRs
  - context-map.json      portable machine map (any assistant, no Claude lock-in)
  - llms-full.txt         technical source-of-truth, derived from existing repo docs
  - ai-config/ai-instructions.md   vendor-neutral working instructions (FR)

Design: zero external dependency (stdlib only, runs off-grid), idempotent,
manual sections survive regeneration, stack auto-detected, driven by a repos
manifest for fleet runs.

Usage:
  gen_context_pack.py <repo_dir>                 # one repo
  gen_context_pack.py --all-repos [--base DIR]   # every repo in the manifest
  gen_context_pack.py <repo_dir> --check         # non-zero if regeneration would change generated content
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

MANUAL_RE = re.compile(
    r"<!-- manual:start -->.*?<!-- manual:end -->", re.DOTALL
)
MANUAL_BLOCK = "<!-- manual:start -->\n_(Zone libre : ce contenu survit à la régénération.)_\n<!-- manual:end -->"


def detect_stack(repo: Path) -> dict:
    """Detect stack from filesystem markers only (no code execution)."""
    markers = {
        "python": ["pyproject.toml", "setup.cfg", "setup.py", "requirements.txt"],
        "node": ["package.json", "pnpm-lock.yaml", "package-lock.json", "yarn.lock"],
        "rust": ["Cargo.toml"],
        "go": ["go.mod"],
        "docker": ["Dockerfile", "docker-compose.yml", "docker-compose.yaml"],
        "helm": ["Chart.yaml"],
        "terraform": ["main.tf"],
    }
    found = sorted(
        name for name, files in markers.items() if any((repo / f).exists() for f in files)
    )
    framework = None
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8"))
            deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
            for fw in ("next", "nuxt", "svelte", "vue", "react", "@angular/core", "astro"):
                if fw in deps:
                    framework = fw
                    break
        except (ValueError, OSError):
            pass
    if (repo / "manage.py").exists():
        framework = "django"
    return {"stacks": found, "framework": framework}


def preserve_manual(existing: str, rendered: str) -> str:
    """Carry manual blocks from an existing file into freshly rendered content."""
    if not existing:
        return rendered
    old_blocks = MANUAL_RE.findall(existing)
    new_blocks = MANUAL_RE.findall(rendered)
    for i, block in enumerate(new_blocks):
        if i < len(old_blocks):
            rendered = rendered.replace(block, old_blocks[i], 1)
    return rendered


def read_if(repo: Path, *names: str) -> str:
    for name in names:
        p = repo / name
        if p.exists():
            return p.read_text(encoding="utf-8", errors="replace")
    return ""


def render_passation(repo: Path, stack: dict) -> str:
    name = repo.name
    stacks = ", ".join(stack["stacks"]) or "n/a"
    fw = stack["framework"] or "n/a"
    return f"""# Passation — {name}

> Handover portable et neutre-fournisseur. Régénéré par `gen_context_pack.py`.
> Secrets : jamais ici — voir OpenBao. Pas de stakeholders/Slack/cloud propriétaire.

- Date : {date.today().isoformat()}
- Stack détectée : {stacks} · framework : {fw}

## État du projet

{MANUAL_BLOCK}

## Place dans l'écosystème

Dépendances de standards : `chrysa/shared-standards`. Voir `context-map.json` pour la carte machine.

{MANUAL_BLOCK}

## Décisions actées (ADR)

Voir `DECISIONS.md` / `docs/adr/` du repo.

{MANUAL_BLOCK}

## Reprise rapide

1. Lire `README.md` puis `llms-full.txt`.
2. Vérifier `ai-config/ai-instructions.md` pour les conventions de travail.
3. `make help` pour les cibles.
"""


def render_context_map(repo: Path, stack: dict) -> str:
    data = {
        "schema": "context-map/1",
        "portable": True,
        "vendor_neutral": True,
        "repo": repo.name,
        "generated": date.today().isoformat(),
        "stack": stack["stacks"],
        "framework": stack["framework"],
        "entrypoints": [
            f for f in ("README.md", "Makefile", "pyproject.toml", "package.json")
            if (repo / f).exists()
        ],
        "docs": [
            f for f in ("architecture.md", "schema.md", "routes.md", "components.md",
                        "DECISIONS.md", "docs")
            if (repo / f).exists()
        ],
        "standards_source": "chrysa/shared-standards",
        "secrets": "OpenBao (never in-repo)",
    }
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def render_llms_full(repo: Path, stack: dict) -> str:
    parts = [f"# {repo.name} — llms-full (derived, do not hand-edit)\n"]
    for src in ("README.md", "architecture.md", "docs/architecture.md",
                "schema.md", "routes.md", "components.md", "CLAUDE.md"):
        body = read_if(repo, src)
        if body:
            parts.append(f"\n\n===== {src} =====\n{body.rstrip()}")
    if len(parts) == 1:
        parts.append("\n_(Aucun doc source trouvé ; enrichir README/architecture.)_\n")
    return "".join(parts) + "\n"


def render_ai_instructions(repo: Path, stack: dict) -> str:
    return f"""# Instructions IA — {repo.name}

> Neutre-fournisseur (portable vers n'importe quel assistant). En français.
> Rangé dans la brique `ai-config`, pas à la racine.

- Respecter `chrysa/shared-standards` (conventions, sécurité, CI).
- Secrets via OpenBao, jamais en clair.
- Tout tourne en conteneur / via `make` — pas d'exécution hôte ad hoc.
- Commits Conventional ; pas de co-auteur IA.

{MANUAL_BLOCK}
"""


def render_dependencies(repo: Path, stack: dict) -> str:
    """Derive a dependency overview from manifests/lockfiles (no install)."""
    lines: list[str] = []
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8"))
            deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
            lines.append(f"## Node ({len(deps)} deps)")
            lines += [f"- `{k}` {v}" for k, v in sorted(deps.items())]
        except (ValueError, OSError):
            pass
    py = read_if(repo, "pyproject.toml")
    if py:
        found = re.findall(r'^\s*"?([A-Za-z0-9._-]+)"?\s*[>=<~]=?', py, re.MULTILINE)
        deps = sorted(set(found))
        if deps:
            lines.append(f"\n## Python ({len(deps)} deps, from pyproject.toml)")
            lines += [f"- `{d}`" for d in deps]
    req = read_if(repo, "requirements.txt")
    if req:
        deps = [ln.strip() for ln in req.splitlines() if ln.strip() and not ln.startswith("#")]
        lines.append(f"\n## Python (requirements.txt, {len(deps)})")
        lines += [f"- `{d}`" for d in deps]
    body = "\n".join(lines) or "_(Aucun manifeste de dépendances détecté.)_"
    return (f"# Dependencies — {repo.name} (derived, do not hand-edit)\n\n"
            f"> Lockfile = contrat. Vulnérabilités suivies hors-repo.\n\n{body}\n")


def render_ecosystem_place(repo: Path, stack: dict) -> str:
    return f"""# Place dans l'écosystème — {repo.name}

- Standards : dépend de `chrysa/shared-standards` (conventions, CI, sécurité).
- Config IA : brique `ai-config` (voir `ai-config/`).
- Contexte machine : `context-map.json`.

## Dépendances / consommateurs (à préciser)

{MANUAL_BLOCK}

## Liens Hub / Notion

{MANUAL_BLOCK}
"""


def render_security(repo: Path, stack: dict) -> str:
    return f"""# Sécurité — {repo.name}

> Note neutre, rangée dans `ai-config/` pour ne pas écraser un `SECURITY.md` de repo.

- Secrets : **OpenBao** uniquement. Jamais de secret en clair (code, logs, fixtures).
- Un secret apparu en clair = compromis → rotation immédiate.
- Détection : scan pre-commit + CI.

{MANUAL_BLOCK}
"""


def render_adr_index(repo: Path, stack: dict) -> str:
    adr_dir = repo / "docs" / "adr"
    rows = []
    if adr_dir.is_dir():
        for f in sorted(adr_dir.glob("*.md")):
            if f.name.upper() in {"INDEX.MD", "README.MD"}:
                continue
            first = ""
            for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
                if line.startswith("# "):
                    first = line[2:].strip()
                    break
            rows.append(f"- [{f.name}]({f.name}) — {first or f.stem}")
    body = "\n".join(rows) or "_(Aucun ADR dans docs/adr/.)_"
    return f"# ADR index — {repo.name} (derived)\n\n{body}\n"


TARGETS = {
    "passation.md": render_passation,
    "context-map.json": render_context_map,
    "llms-full.txt": render_llms_full,
    "ai-config/ai-instructions.md": render_ai_instructions,
    "DEPENDENCIES.md": render_dependencies,
    "ecosystem-place.md": render_ecosystem_place,
    "ai-config/security.md": render_security,
    "docs/adr/INDEX.md": render_adr_index,
}


def process_repo(repo: Path, check: bool) -> bool:
    """Return True if up-to-date (or written); False if --check found drift."""
    stack = detect_stack(repo)
    ok = True
    for rel, render in TARGETS.items():
        out = repo / rel
        rendered = render(repo, stack)
        existing = out.read_text(encoding="utf-8") if out.exists() else ""
        final = preserve_manual(existing, rendered)
        if check:
            if existing != final:
                print(f"DRIFT {repo.name}/{rel}")
                ok = False
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(final, encoding="utf-8")
        print(f"wrote {repo.name}/{rel}")
    return ok


def load_manifest_repos(base: Path) -> list[Path]:
    """Read repo names from a repos.yml manifest (minimal parser, stdlib only)."""
    manifest = Path(__file__).resolve().parent.parent / "repos.yml"
    names: list[str] = []
    if manifest.exists():
        for line in manifest.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*-\s*name:\s*([A-Za-z0-9._-]+)", line) or \
                re.match(r"\s*-\s*([A-Za-z0-9._-]+)\s*$", line)
            if m:
                names.append(m.group(1))
    return [base / n for n in dict.fromkeys(names) if (base / n).is_dir()]


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate the portable AI context pack.")
    ap.add_argument("repo_dir", nargs="?", help="Path to a single repository")
    ap.add_argument("--all-repos", action="store_true", help="Apply to every repo in the manifest")
    ap.add_argument("--base", default=".", help="Base dir holding cloned repos (with --all-repos)")
    ap.add_argument("--check", action="store_true", help="Report drift, write nothing, non-zero on drift")
    args = ap.parse_args()

    if args.all_repos:
        repos = load_manifest_repos(Path(args.base).resolve())
        if not repos:
            print("no repos found from manifest under --base", file=sys.stderr)
            return 2
        all_ok = all(process_repo(r, args.check) for r in repos)
        return 0 if all_ok else 1
    if not args.repo_dir:
        ap.error("provide a repo_dir or --all-repos")
    return 0 if process_repo(Path(args.repo_dir).resolve(), args.check) else 1


if __name__ == "__main__":
    raise SystemExit(main())
