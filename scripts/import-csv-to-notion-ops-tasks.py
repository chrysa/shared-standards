#!/usr/bin/env python3
"""
import-csv-to-notion-ops-tasks.py
Import ECOSYSTEM_TASKS.csv (105 tasks) dans DB Notion Ops Tasks.

Prérequis:
    pip install requests
    export NOTION_TOKEN=secret_xxx
    export NOTION_OPS_TASKS_DB_ID=<data_source_id>

Usage:
    ./import-csv-to-notion-ops-tasks.py ECOSYSTEM_TASKS_2026-04-19.csv [--dry-run]

CSV attendu (colonnes) :
    T_id, titre, priorité, effort, projet, statut, description, dépendances
"""

import csv
import json
import os
import sys
import argparse
from pathlib import Path

try:
    import requests
except ImportError:
    print("Erreur : pip install requests")
    sys.exit(1)

NOTION_TOKEN = os.environ.get("NOTION_TOKEN")
DB_ID = os.environ.get("NOTION_OPS_TASKS_DB_ID")
API_URL = "https://api.notion.com/v1/pages"
API_VERSION = "2022-06-28"


def parse_csv(path: Path) -> list[dict]:
    rows = []
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({k.strip(): v.strip() for k, v in row.items()})
    return rows


def to_notion_properties(row: dict) -> dict:
    """Adapte la ligne CSV au format Notion properties.
    Hypothèse sur le schéma DB Ops Tasks :
        - Name (title)
        - Priority (select: P0/P1/P2/P3)
        - Effort (number)
        - Project (select or relation)
        - Status (select)
        - Description (rich_text)
    """
    props = {
        "Name": {
            "title": [{"text": {"content": row.get("titre", row.get("T_id", "Unnamed"))[:200]}}]
        }
    }

    prio = row.get("priorité") or row.get("priority")
    if prio:
        props["Priority"] = {"select": {"name": prio}}

    effort = row.get("effort")
    if effort and effort.replace(".", "").isdigit():
        props["Effort"] = {"number": float(effort)}

    statut = row.get("statut") or row.get("status") or "Backlog"
    props["Status"] = {"select": {"name": statut}}

    projet = row.get("projet") or row.get("project")
    if projet:
        props["Project"] = {"select": {"name": projet}}

    desc = row.get("description")
    if desc:
        props["Description"] = {
            "rich_text": [{"text": {"content": desc[:2000]}}]
        }

    return props


def create_page(row: dict, dry_run: bool = False) -> bool:
    if not NOTION_TOKEN or not DB_ID:
        print("❌ NOTION_TOKEN ou NOTION_OPS_TASKS_DB_ID manquant")
        return False

    payload = {
        "parent": {"database_id": DB_ID},
        "properties": to_notion_properties(row),
    }

    if dry_run:
        print(f"[DRY-RUN] {row.get('T_id', 'new')} · {row.get('titre', '')[:60]}")
        return True

    resp = requests.post(
        API_URL,
        headers={
            "Authorization": f"Bearer {NOTION_TOKEN}",
            "Notion-Version": API_VERSION,
            "Content-Type": "application/json",
        },
        data=json.dumps(payload),
        timeout=15,
    )
    if resp.status_code == 200:
        print(f"✅ {row.get('T_id', 'new')} · {row.get('titre', '')[:60]}")
        return True
    else:
        print(f"❌ {row.get('T_id', 'new')} · HTTP {resp.status_code} · {resp.text[:100]}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Import CSV to Notion Ops Tasks")
    parser.add_argument("csv_file", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--rate-limit", type=float, default=0.35, help="seconds between calls")
    args = parser.parse_args()

    if not args.csv_file.exists():
        print(f"❌ Fichier introuvable : {args.csv_file}")
        sys.exit(1)

    rows = parse_csv(args.csv_file)
    print(f"→ {len(rows)} lignes CSV à importer")

    import time
    success = 0
    for i, row in enumerate(rows, 1):
        ok = create_page(row, dry_run=args.dry_run)
        if ok:
            success += 1
        # Rate limit Notion = 3 req/sec
        if not args.dry_run:
            time.sleep(args.rate_limit)

    print(f"\n═════ Résumé ═════")
    print(f"Importé : {success}/{len(rows)}")
    print(f"Échec   : {len(rows) - success}")


if __name__ == "__main__":
    main()
