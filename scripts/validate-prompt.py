#!/usr/bin/env python3
"""
validate-prompt.py — Validation locale de prompts destinés à Claude.

Critères extraits de l'article plume-ecriture.fr/.../prompt-engineering-claude-debutants-tpe-pme/
et adaptés au contexte chrysa (CLAUDE.md global, FR+EN, roles PM/Tech Lead/etc.).

Usage:
    # Depuis un fichier
    python3 validate-prompt.py path/to/prompt.md

    # Depuis stdin
    cat my-prompt.txt | python3 validate-prompt.py -

    # Mode strict (exit 1 si score < seuil)
    python3 validate-prompt.py --min-score 6 path/to/prompt.md

    # JSON pour CI/intégration
    python3 validate-prompt.py --format=json path/to/prompt.md

    # Hook pre-commit (regarde uniquement les .prompt.md stagés)
    python3 validate-prompt.py --pre-commit

Exit codes:
    0   prompt validé (score >= min-score)
    1   prompt en-dessous du seuil
    2   fichier introuvable / stdin vide
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# ─── Couleurs terminal ───────────────────────────────────────────────
C_RESET = "\033[0m"
C_GREEN = "\033[0;32m"
C_YELLOW = "\033[0;33m"
C_RED = "\033[0;31m"
C_BLUE = "\033[0;34m"
C_GRAY = "\033[0;90m"


# ─── Patterns (FR + EN) ──────────────────────────────────────────────
PATTERNS_ROLE = [
    r"\btu es\b", r"\bvous êtes\b", r"\ben tant que\b",
    r"\byou are\b", r"\bact as\b", r"\bagis(?:sez)? (?:en|comme)\b",
    r"\bassume the role\b",
]

PATTERNS_CONTEXT = [
    r"\bje (?:suis|dirige|travaille|cherche|veux|souhaite|ai besoin)\b",
    r"\bmon (?:objectif|but|besoin|contexte)\b",
    r"\bmon?\s+(?:équipe|entreprise|projet|client)\b",
    r"\bi (?:am|work|need|want|run)\b",
    r"\bmy (?:goal|team|company|project|client|context)\b",
    r"\bcontext(?:e|ual)?\s*:",
]

PATTERNS_OBJECTIVE = [
    r"\b(?:objectif|but|finalité|mission|goal|aim)\b\s*:",
    r"\bje (?:veux|souhaite|cherche|voudrais)\b",
    r"\bi (?:want|need|would like|am looking)\b",
    r"\bproduire\b|\bcréer\b|\brédiger\b|\bgénérer\b",
    r"\bproduce\b|\bcreate\b|\bwrite\b|\bgenerate\b",
]

PATTERNS_STRUCTURE = [
    r"^\s*[-*•]\s+",  # bullets
    r"^\s*\d+[.)]\s+",  # numbered
    r"^\s*#{1,6}\s+",  # markdown headers
    r"^\s*[A-Z][A-Z0-9_ ]{3,}:\s*$",  # SECTION:
    r"<[a-z_]+>",  # XML-ish tags
]

PATTERNS_TONE = [
    r"\bton\s*:", r"\btone\s*:", r"\bstyle\s*:", r"\bregistre\b", r"\bregister\b",
    r"\b(?:chaleureux|professionnel|formel|informel|accessible|expert|pédagogique|concis)\b",
    r"\b(?:warm|professional|formal|informal|casual|expert|pedagogical|concise)\b",
]

PATTERNS_EXAMPLES = [
    r"\bexemples?\b\s*:", r"\bex\.\s*:", r"\bexample[s]?\s*:",
    r"\bvoici (?:un|quelques)\b", r"\bhere (?:is|are)\b",
    r"```",  # code fences often used to delimit examples
    r"\bfew[-\s]shot\b",
]

PATTERNS_CONSTRAINTS = [
    r"\b(?:max(?:imum)?|min(?:imum)?|limite|limit)\b.*\d+",
    r"\b\d+\s*(?:mots?|words?|caractères?|chars?|lignes?|lines?|sections?|bullets?)\b",
    r"\b(?:contrainte[s]?|constraints?|requirements?)\b\s*:",
    r"\bne pas\b|\bdon'?t\b|\bavoid\b|\bévite[rz]?\b|\bjamais\b|\bnever\b",
    r"\binterdit[s]?\b|\bforbidden\b|\bbanned\b",
]

PATTERNS_FORMAT = [
    r"\bformat\s*:", r"\boutput\s*:", r"\bsortie\s*:",
    r"\brenvoie[rz]?\b|\breturn\b|\brends?\b",
    r"\b(?:json|yaml|xml|markdown|html|csv)\b",
]

# Anti-patterns (red flags)
ANTI_PATTERNS = [
    (r"^\s*écris[- ]?moi\s+(?:un|une)\s+\w+\s*\.?\s*$",
     "demande mono-ligne générique sans contexte"),
    (r"^\s*write\s+(?:me\s+)?(?:an?|the)\s+\w+\s*\.?\s*$",
     "one-liner generic request"),
    (r"(?i)fais\s+(?:de ton mieux|au mieux|comme tu veux)",
     "décharge de la responsabilité sur le modèle"),
    (r"(?i)(?:devine[rz]?|guess)\s+(?:what|ce que|quoi)",
     "demande à Claude de deviner (anti-pattern majeur)"),
]


# ─── Modèle de résultat ──────────────────────────────────────────────
@dataclass
class Check:
    name: str
    status: str  # "PASS" | "WARN" | "FAIL"
    message: str
    weight: int = 1

    def symbol(self) -> str:
        return {"PASS": "✓", "WARN": "~", "FAIL": "✗"}[self.status]

    def color(self) -> str:
        return {"PASS": C_GREEN, "WARN": C_YELLOW, "FAIL": C_RED}[self.status]


@dataclass
class Report:
    prompt: str
    checks: list[Check] = field(default_factory=list)
    anti_patterns: list[str] = field(default_factory=list)

    @property
    def score(self) -> float:
        total_weight = sum(c.weight for c in self.checks)
        if total_weight == 0:
            return 0.0
        got = sum(
            c.weight * {"PASS": 1.0, "WARN": 0.5, "FAIL": 0.0}[c.status]
            for c in self.checks
        )
        return round(10 * got / total_weight, 1)

    @property
    def verdict(self) -> str:
        s = self.score
        if s >= 8:
            return "EXCELLENT"
        if s >= 6:
            return "ACCEPTABLE"
        if s >= 4:
            return "INSUFFISANT"
        return "MAUVAIS"

    def to_json(self) -> dict:
        return {
            "score": self.score,
            "verdict": self.verdict,
            "checks": [
                {"name": c.name, "status": c.status, "message": c.message, "weight": c.weight}
                for c in self.checks
            ],
            "anti_patterns": self.anti_patterns,
            "length_chars": len(self.prompt),
            "length_lines": self.prompt.count("\n") + 1,
        }


# ─── Moteur d'analyse ────────────────────────────────────────────────
def _match_any(patterns: list[str], text: str, flags: int = re.IGNORECASE | re.MULTILINE) -> bool:
    return any(re.search(p, text, flags) for p in patterns)


def _count_matches(patterns: list[str], text: str, flags: int = re.IGNORECASE | re.MULTILINE) -> int:
    return sum(len(re.findall(p, text, flags)) for p in patterns)


def analyze(prompt: str) -> Report:
    report = Report(prompt=prompt)
    text = prompt.strip()

    # 1. Longueur
    n_chars = len(text)
    n_words = len(text.split())
    if n_words < 10:
        report.checks.append(Check(
            "longueur", "FAIL",
            f"prompt trop court ({n_words} mots) — <10 mots est rarement suffisant",
            weight=2,
        ))
    elif n_words < 30:
        report.checks.append(Check(
            "longueur", "WARN",
            f"prompt court ({n_words} mots) — envisage d'ajouter contexte/exemples",
            weight=2,
        ))
    elif n_words > 2000:
        report.checks.append(Check(
            "longueur", "WARN",
            f"prompt très long ({n_words} mots) — risque de noyer l'essentiel",
            weight=2,
        ))
    else:
        report.checks.append(Check(
            "longueur", "PASS",
            f"longueur raisonnable ({n_words} mots)",
            weight=2,
        ))

    # 2. Rôle défini
    if _match_any(PATTERNS_ROLE, text):
        report.checks.append(Check("rôle", "PASS", "rôle explicitement défini", weight=2))
    else:
        report.checks.append(Check(
            "rôle", "FAIL",
            "aucun rôle défini · ajoute 'Tu es un [métier] spécialisé en [domaine]'",
            weight=2,
        ))

    # 3. Contexte
    if _match_any(PATTERNS_CONTEXT, text):
        report.checks.append(Check("contexte", "PASS", "contexte utilisateur présent", weight=2))
    else:
        report.checks.append(Check(
            "contexte", "FAIL",
            "contexte manquant · précise qui tu es et à qui tu t'adresses",
            weight=2,
        ))

    # 4. Objectif explicite
    if _match_any(PATTERNS_OBJECTIVE, text):
        report.checks.append(Check("objectif", "PASS", "objectif explicite", weight=1))
    else:
        report.checks.append(Check(
            "objectif", "WARN",
            "objectif flou · formule ce que tu veux obtenir",
            weight=1,
        ))

    # 5. Structure
    struct_count = _count_matches(PATTERNS_STRUCTURE, text)
    if struct_count >= 3:
        report.checks.append(Check(
            "structure", "PASS", f"{struct_count} marqueurs structurels détectés", weight=1,
        ))
    elif struct_count >= 1:
        report.checks.append(Check(
            "structure", "WARN",
            f"structure légère ({struct_count} marqueur) · utilise listes/headers/tags",
            weight=1,
        ))
    else:
        report.checks.append(Check(
            "structure", "FAIL",
            "aucune structure visible · organise en sections avec listes ou headers",
            weight=1,
        ))

    # 6. Ton / style
    if _match_any(PATTERNS_TONE, text):
        report.checks.append(Check("ton/style", "PASS", "ton ou registre précisé", weight=1))
    else:
        report.checks.append(Check(
            "ton/style", "WARN",
            "ton non précisé · ajoute registre (formel/chaleureux/technique/…)",
            weight=1,
        ))

    # 7. Exemples
    if _match_any(PATTERNS_EXAMPLES, text):
        report.checks.append(Check("exemples", "PASS", "exemples présents (few-shot)", weight=1))
    else:
        report.checks.append(Check(
            "exemples", "WARN",
            "aucun exemple · un extrait de style aide Claude à calibrer",
            weight=1,
        ))

    # 8. Contraintes
    if _match_any(PATTERNS_CONSTRAINTS, text):
        report.checks.append(Check("contraintes", "PASS", "contraintes / interdictions présentes", weight=1))
    else:
        report.checks.append(Check(
            "contraintes", "WARN",
            "aucune contrainte · précise limites (mots, sections, interdictions)",
            weight=1,
        ))

    # 9. Format de sortie
    if _match_any(PATTERNS_FORMAT, text):
        report.checks.append(Check("format", "PASS", "format de sortie spécifié", weight=1))
    else:
        report.checks.append(Check(
            "format", "WARN",
            "format de sortie non spécifié · ajoute 'renvoie en JSON/md/…'",
            weight=1,
        ))

    # 10. Anti-patterns
    for pattern, label in ANTI_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE | re.MULTILINE):
            report.anti_patterns.append(label)

    if report.anti_patterns:
        report.checks.append(Check(
            "anti-patterns", "FAIL",
            f"{len(report.anti_patterns)} anti-pattern(s) détecté(s)",
            weight=2,
        ))
    else:
        report.checks.append(Check("anti-patterns", "PASS", "aucun anti-pattern détecté", weight=2))

    return report


# ─── Rendu ───────────────────────────────────────────────────────────
def render_text(report: Report) -> str:
    lines = []
    lines.append(f"{C_BLUE}╔══════════════════════════════════════════╗{C_RESET}")
    lines.append(f"{C_BLUE}║ Prompt Validator — verdict: {report.verdict:<12} ║{C_RESET}")
    lines.append(f"{C_BLUE}╚══════════════════════════════════════════╝{C_RESET}")
    lines.append("")
    lines.append(f"Score : {report.score}/10  ·  {len(report.prompt.split())} mots  ·  {report.prompt.count(chr(10))+1} lignes")
    lines.append("")
    for c in report.checks:
        lines.append(f"  {c.color()}{c.symbol()}{C_RESET} {c.name:<14} {C_GRAY}{c.message}{C_RESET}")
    if report.anti_patterns:
        lines.append("")
        lines.append(f"{C_RED}⚠ Anti-patterns détectés :{C_RESET}")
        for ap in report.anti_patterns:
            lines.append(f"  - {ap}")
    lines.append("")
    return "\n".join(lines)


# ─── Mode pre-commit ─────────────────────────────────────────────────
def staged_prompt_files() -> list[Path]:
    """Retourne les .prompt.md / prompts/*.md stagés via git."""
    try:
        out = subprocess.check_output(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
            text=True,
        )
    except subprocess.CalledProcessError:
        return []
    files = []
    for line in out.splitlines():
        p = Path(line)
        if not p.exists():
            continue
        if p.suffix == ".md" and ("prompt" in p.name.lower() or "prompt" in str(p.parent).lower()):
            files.append(p)
    return files


# ─── Main ────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(description="Valide un prompt Claude.")
    parser.add_argument("path", nargs="?", help="Fichier prompt (- pour stdin)")
    parser.add_argument("--min-score", type=float, default=6.0,
                        help="Seuil d'acceptation (défaut: 6.0)")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--pre-commit", action="store_true",
                        help="Mode pre-commit: valide tous les prompts stagés")
    args = parser.parse_args()

    # Mode pre-commit : itère sur les fichiers stagés
    if args.pre_commit:
        files = staged_prompt_files()
        if not files:
            print("ℹ️  Aucun fichier prompt stagé à valider")
            return 0
        worst = 10.0
        for f in files:
            prompt = f.read_text(encoding="utf-8")
            report = analyze(prompt)
            print(f"\n=== {f} ===")
            print(render_text(report) if args.format == "text"
                  else json.dumps(report.to_json(), indent=2, ensure_ascii=False))
            worst = min(worst, report.score)
        if worst < args.min_score:
            print(f"\n{C_RED}✗ Pire score {worst}/{args.min_score} — commit bloqué{C_RESET}")
            return 1
        return 0

    # Mode simple
    if not args.path:
        parser.print_help()
        return 2
    if args.path == "-":
        prompt = sys.stdin.read()
        if not prompt.strip():
            print("stdin vide", file=sys.stderr)
            return 2
    else:
        p = Path(args.path)
        if not p.exists():
            print(f"fichier introuvable: {p}", file=sys.stderr)
            return 2
        prompt = p.read_text(encoding="utf-8")

    report = analyze(prompt)
    if args.format == "json":
        print(json.dumps(report.to_json(), indent=2, ensure_ascii=False))
    else:
        print(render_text(report))

    return 0 if report.score >= args.min_score else 1


if __name__ == "__main__":
    sys.exit(main())
