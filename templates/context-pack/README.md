# context-pack

Brique canonique : un **pack de contexte IA portable et neutre-fournisseur**, généré
depuis le code réel, propagé à tous les repos depuis un point de vérité unique.

## Ce qui est généré (par repo)

| Fichier | Rôle |
| --- | --- |
| `passation.md` | Handover : état, place dans l'écosystème, ADR. Zones manuelles préservées. |
| `context-map.json` | Carte machine **portable** (n'importe quel assistant, aucun lock-in Claude). |
| `llms-full.txt` | Source de vérité technique **dérivée** des docs existantes (README/architecture/schema/routes/CLAUDE). |
| `ai-config/ai-instructions.md` | Conventions de travail neutres-fournisseur (FR). |

## Principes

- **Zéro dépendance externe** (stdlib seule) → tourne off-grid.
- **Idempotent** : `--check` échoue si une régénération changerait le contenu généré.
- **Sections manuelles préservées** : tout entre `<!-- manual:start -->` et
  `<!-- manual:end -->` survit à la régénération.
- **Détection de stack** par marqueurs fichiers (aucune exécution de code cible).
- **Secrets** : jamais dans le pack → OpenBao.

## Usage

```sh
python3 scripts/gen_context_pack.py <repo_dir>              # un repo
python3 scripts/gen_context_pack.py <repo_dir> --check      # gate de dérive
python3 scripts/gen_context_pack.py --all-repos --base <dir-des-clones>
```

`--all-repos` lit `repos.yml` (le manifeste existant de shared-standards) et applique
le pack à chaque repo cloné sous `--base`.

## Déploiement « tous les repos »

Un seul point de vérité propagé, jamais 90 copies écrites à la main :

```sh
scripts/clone-profile.sh full ./_repos        # cloner le parc (profil)
python3 scripts/gen_context_pack.py --all-repos --base ./_repos
# revue git par repo, puis commit
```

## Notion (passe 2, hors de cette brique)

La sync Notion se branche **en aval** : `context-map.json` fournit déjà les champs
machine. Mapping vers la DB chrysa-V2 + sens de sync à définir avant de l'ajouter.

## CI

`workflows/context-pack-check.yml` lance `--check` : la CI échoue si le pack a dérivé
du code (doc non régénérée).
