#!/usr/bin/env bash
# generate-portfolio-html.sh
# Génère une landing page HTML statique listant les projets chrysa
# Data source : scan des repos locaux + READMEs + détection stack
# Output : portfolio.html (self-contained, mode clair/sombre, filtre par rôle)
#
# Deux modes :
#   INTERNE (défaut) : tout inclus — y compris travaux (domaine Maison) et aménagement Notion (meta-work)
#   EXTERNE (--external) : filtre travaux + aménagement + tooling interne — version à transmettre à des externes
#
# Usage :
#   ./generate-portfolio-html.sh                                     # interne par défaut
#   ./generate-portfolio-html.sh --external                          # version pour externes
#   ./generate-portfolio-html.sh --external --output=portfolio-public.html

set -uo pipefail

CHRYSA_ROOT="${CHRYSA_ROOT:-/home/anthony/Documents/perso/projects/chrysa}"
OUTPUT="$CHRYSA_ROOT/portfolio.html"
EXTERNAL=false

for arg in "$@"; do
    case "$arg" in
        --external) EXTERNAL=true ;;
        --output=*) OUTPUT="${arg#--output=}" ;;
        *) ;;
    esac
done

# Si --external et pas d'output custom : default vers portfolio-public.html
if $EXTERNAL && [[ "$OUTPUT" == "$CHRYSA_ROOT/portfolio.html" ]]; then
    OUTPUT="$CHRYSA_ROOT/portfolio-public.html"
fi

# ─── Liste d'exclusion pour la vue EXTERNE ──────────────────────────
# Repos / sujets qui ne doivent PAS apparaître dans la version partagée
# avec des recruteurs ou personnes externes.
EXCLUDE_EXTERNAL=(
    # Travaux (domaine Maison)
    "travaux"
    "maison"
    "portail-solaire"
    # Aménagement / meta-work
    "notion-automation"
    "ecosystem-reorg"
    "drive-cleanup"
    # Tooling / config interne
    "chrysa-bootstrap"
    "pycharm_settings"
    "42_save"
    "skills"
    "standards-updates"
    # Ajoute ici d'autres repos à masquer pour l'externe
)

is_excluded_external() {
    local name=$1
    for pat in "${EXCLUDE_EXTERNAL[@]}"; do
        [[ "$name" == *"$pat"* ]] && return 0
    done
    return 1
}

cd "$CHRYSA_ROOT" || exit 1

if $EXTERNAL; then
    echo "→ Mode EXTERNE · filtrage travaux/aménagement/tooling activé"
else
    echo "→ Mode INTERNE · tout inclus"
fi

# Collecte données projets
PROJECTS_JSON=""
first=true
for d in */; do
    d="${d%/}"
    [[ "$d" == "_archived" ]] && continue
    [[ ! -d "$d/.git" ]] && continue

    # Filtre externe
    if $EXTERNAL && is_excluded_external "$d"; then
        echo "  ⊘ exclu (externe) : $d"
        continue
    fi

    # Métadonnées
    name="$d"
    desc=""
    if [[ -f "$d/README.md" ]]; then
        desc=$(head -20 "$d/README.md" | grep -v "^#" | grep -v "^$" | head -1 | sed 's/"/\\"/g' | cut -c1-200)
    fi

    stack="unknown"
    [[ -f "$d/pyproject.toml" || -f "$d/setup.py" ]] && stack="Python"
    [[ -f "$d/package.json" ]] && stack="Node/TS"
    [[ -f "$d/go.mod" ]] && stack="Go"
    [[ -f "$d/Cargo.toml" ]] && stack="Rust"

    has_docker="No"
    { [[ -f "$d/Dockerfile" ]] || [[ -f "$d/docker-compose.yml" ]]; } && has_docker="Yes"

    has_ci="No"
    [[ -d "$d/.github/workflows" ]] && [[ -n "$(ls "$d/.github/workflows"/*.yml 2>/dev/null)" ]] && has_ci="Yes"

    last_commit=""
    (cd "$d" && last_commit=$(git log -1 --format="%cr" 2>/dev/null || echo "never"))

    remote=""
    (cd "$d" && remote=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]|https://github.com/|; s|\.git$||'))

    # ─── Enrichissement depuis portfolio-metadata.yml (si présent + python3 dispo) ───
    role=""; status_proj=""; valeur=""; bloqueurs=""; budget=""; is_public="true"
    META="$CHRYSA_ROOT/shared-standards/portfolio-metadata.yml"
    if [[ -f "$META" ]] && command -v python3 &>/dev/null; then
        meta_json=$(python3 -c "
import sys, yaml, json
try:
    m = yaml.safe_load(open('$META'))
    e = m.get('$d', {}) if m else {}
    b = e.get('budget_annuel_eur', {})
    print(json.dumps({
        'role': e.get('role', ''),
        'status': e.get('status', ''),
        'valeur': e.get('valeur_plateforme', ''),
        'bloqueurs': ' · '.join(e.get('bloqueurs', [])) if e.get('bloqueurs') else '',
        'budget': f\"infra {b.get('infra',0)}€ · saas {b.get('saas',0)}€ · {b.get('effort_h',0)}h\" if b else '',
        'public': str(e.get('public', True)).lower()
    }))
except Exception as exc:
    print('{}')
" 2>/dev/null || echo "{}")
        role=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('role',''))" 2>/dev/null)
        status_proj=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null)
        valeur=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('valeur','').replace('\"','\\\\\"'))" 2>/dev/null)
        bloqueurs=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('bloqueurs','').replace('\"','\\\\\"'))" 2>/dev/null)
        budget=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('budget',''))" 2>/dev/null)
        is_public=$(echo "$meta_json" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('public','true'))" 2>/dev/null)
    fi

    # Filtre supplémentaire : public=false → exclu du mode externe
    if $EXTERNAL && [[ "$is_public" == "false" ]]; then
        echo "  ⊘ exclu (externe, public=false) : $d"
        continue
    fi

    $first || PROJECTS_JSON+=","
    PROJECTS_JSON+=$(printf '{"name":"%s","desc":"%s","stack":"%s","docker":"%s","ci":"%s","last":"%s","remote":"%s","role":"%s","status":"%s","valeur":"%s","bloqueurs":"%s","budget":"%s"}' \
        "$name" "$desc" "$stack" "$has_docker" "$has_ci" "$last_commit" "$remote" \
        "$role" "$status_proj" "$valeur" "$bloqueurs" "$budget")
    first=false
done

# HTML avec CSS/JS inline
cat > "$OUTPUT" <<HTML_EOF
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Portfolio chrysa$($EXTERNAL && echo " (version publique)")</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  :root { --bg: #0f172a; --fg: #e2e8f0; --card: #1e293b; --accent: #3b82f6; --muted: #64748b; }
  body.light { --bg: #f8fafc; --fg: #0f172a; --card: #ffffff; --muted: #64748b; }
  * { box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: var(--bg); color: var(--fg); margin: 0; padding: 2rem; transition: all 0.2s; }
  h1 { margin: 0 0 0.5rem 0; font-size: 2rem; }
  .subtitle { color: var(--muted); margin-bottom: 2rem; }
  .controls { display: flex; gap: 1rem; margin-bottom: 2rem; flex-wrap: wrap; }
  .controls input, .controls select, .controls button { padding: 0.5rem 1rem; border: 1px solid var(--muted); background: var(--card); color: var(--fg); border-radius: 6px; font-size: 0.9rem; }
  .controls input { flex: 1; min-width: 200px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem; }
  .card { background: var(--card); padding: 1.5rem; border-radius: 12px; border: 1px solid transparent; transition: all 0.15s; }
  .card:hover { border-color: var(--accent); transform: translateY(-2px); }
  .card h3 { margin: 0 0 0.5rem 0; font-size: 1.1rem; }
  .card .stack { display: inline-block; background: var(--accent); color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; margin-right: 4px; }
  .card .badge { display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 0.7rem; margin-right: 4px; }
  .yes { background: #10b981; color: white; }
  .no { background: #6b7280; color: white; }
  .card .desc { color: var(--muted); font-size: 0.85rem; margin: 0.5rem 0; line-height: 1.4; min-height: 3em; }
  .card .meta { font-size: 0.75rem; color: var(--muted); margin-top: 0.5rem; display: flex; justify-content: space-between; }
  .card a { color: var(--accent); text-decoration: none; font-size: 0.85rem; }
  .card a:hover { text-decoration: underline; }
  .stats { color: var(--muted); font-size: 0.85rem; margin-bottom: 1rem; }
  .role-Socle { background: #ef4444; color: white; }
  .role-Actif { background: #10b981; color: white; }
  .role-Opportuniste { background: #3b82f6; color: white; }
  .role-Gelé { background: #6b7280; color: white; }
  .role-Vision { background: #a855f7; color: white; }
  .card .valeur { font-size: 0.85rem; color: var(--fg); margin: 0.5rem 0; font-style: italic; }
  .card .bloqueurs { font-size: 0.8rem; color: #f59e0b; margin: 0.5rem 0; padding: 6px 8px; background: rgba(245, 158, 11, 0.1); border-left: 3px solid #f59e0b; border-radius: 3px; }
  .card .budget { font-size: 0.75rem; color: var(--muted); margin-top: 0.25rem; padding-top: 0.5rem; border-top: 1px dashed var(--muted); }
</style>
</head>
<body>
<h1>📦 Portfolio chrysa$($EXTERNAL && echo " — version publique")</h1>
<p class="subtitle">Vue générée le $(date +%Y-%m-%d)$($EXTERNAL && echo " · travaux et outillage interne filtrés" || echo " · vue interne complète")</p>

<div class="controls">
  <input type="text" id="search" placeholder="Chercher par nom ou description..." oninput="filter()">
  <select id="stack" onchange="filter()">
    <option value="">Tous stacks</option>
    <option value="Python">Python</option>
    <option value="Node/TS">Node/TS</option>
    <option value="Go">Go</option>
    <option value="Rust">Rust</option>
    <option value="unknown">Non identifié</option>
  </select>
  <select id="docker" onchange="filter()">
    <option value="">Docker : tous</option>
    <option value="Yes">Avec Docker</option>
    <option value="No">Sans Docker</option>
  </select>
  <select id="role" onchange="filter()">
    <option value="">Tous rôles</option>
    <option value="Socle">Socle</option>
    <option value="Actif">Actif</option>
    <option value="Opportuniste">Opportuniste</option>
    <option value="Gelé">Gelé</option>
    <option value="Vision">Vision</option>
  </select>
  <button onclick="toggleTheme()">🌙/☀️</button>
</div>

<div class="stats" id="stats"></div>
<div class="grid" id="grid"></div>

<script>
const projects = [$PROJECTS_JSON];

function render(list) {
  const grid = document.getElementById('grid');
  grid.innerHTML = list.map(p => \`
    <div class="card">
      <h3>\${p.name} \${p.status ? '<span class="badge no">'+p.status+'</span>' : ''}</h3>
      <span class="stack">\${p.stack}</span>
      \${p.role ? '<span class="badge role-'+p.role+'">'+p.role+'</span>' : ''}
      <span class="badge \${p.docker === 'Yes' ? 'yes' : 'no'}">Docker: \${p.docker}</span>
      <span class="badge \${p.ci === 'Yes' ? 'yes' : 'no'}">CI: \${p.ci}</span>
      \${p.valeur ? '<div class="valeur">💡 '+p.valeur+'</div>' : ''}
      <div class="desc">\${p.desc || 'Pas de description'}</div>
      \${p.bloqueurs ? '<div class="bloqueurs">🚧 '+p.bloqueurs+'</div>' : ''}
      \${p.budget ? '<div class="budget">💶 '+p.budget+'</div>' : ''}
      <div class="meta">
        <span>Last: \${p.last}</span>
        \${p.remote ? '<a href="' + p.remote + '" target="_blank">GitHub →</a>' : ''}
      </div>
    </div>
  \`).join('');

  // Calcul budget total affiché
  const totalInfra = list.reduce((s,p) => { const m = p.budget.match(/infra (\d+)€/); return s + (m ? parseInt(m[1]) : 0); }, 0);
  const totalSaas  = list.reduce((s,p) => { const m = p.budget.match(/saas (\d+)€/); return s + (m ? parseInt(m[1]) : 0); }, 0);
  const totalHours = list.reduce((s,p) => { const m = p.budget.match(/(\d+)h/); return s + (m ? parseInt(m[1]) : 0); }, 0);
  document.getElementById('stats').textContent =
    \`\${list.length} projet(s) affichés sur \${projects.length} · budget annuel cumulé : \${totalInfra}€ infra + \${totalSaas}€ SaaS · \${totalHours}h effort solo dev\`;
}

function filter() {
  const q = document.getElementById('search').value.toLowerCase();
  const stack = document.getElementById('stack').value;
  const docker = document.getElementById('docker').value;
  const role = document.getElementById('role').value;
  const filtered = projects.filter(p => {
    const matchQ = !q || p.name.toLowerCase().includes(q) || (p.desc && p.desc.toLowerCase().includes(q)) || (p.valeur && p.valeur.toLowerCase().includes(q));
    const matchStack = !stack || p.stack === stack;
    const matchDocker = !docker || p.docker === docker;
    const matchRole = !role || p.role === role;
    return matchQ && matchStack && matchDocker && matchRole;
  });
  render(filtered);
}

function toggleTheme() {
  document.body.classList.toggle('light');
  localStorage.setItem('theme', document.body.classList.contains('light') ? 'light' : 'dark');
}

if (localStorage.getItem('theme') === 'light') document.body.classList.add('light');
render(projects);
</script>
</body>
</html>
HTML_EOF

echo "✅ Portfolio généré : $OUTPUT"
echo "   $(wc -l < "$OUTPUT") lignes · $(ls -la "$OUTPUT" | awk '{print $5}') bytes"
echo "   Ouvre avec : xdg-open $OUTPUT"
