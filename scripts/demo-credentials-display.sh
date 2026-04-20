#!/usr/bin/env bash
# demo-credentials-display.sh
# Template pour afficher les credentials auto-générés d'une plateforme en local
# À inclure dans docker-compose de chaque projet avec auth
#
# Principe : quand le user lance `make demo`, les credentials auto-créés
# s'affichent dans un encart clair et copiable pour une démo fonctionnelle
#
# Usage dans docker-compose.yml :
#   service:
#     image: myapp
#     environment:
#       - AUTO_CREATE_ADMIN=true
#       - DEMO_MODE=true
#     entrypoint: ["/scripts/demo-credentials-display.sh", "original-entrypoint"]

set -uo pipefail

# Génère credentials si AUTO_CREATE_ADMIN=true
if [[ "${AUTO_CREATE_ADMIN:-false}" == "true" ]]; then
    ADMIN_USER="${ADMIN_USER:-admin@chrysa.dev}"
    ADMIN_PASS="${ADMIN_PASS:-$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-12)}"

    # Export pour l'app
    export ADMIN_USER ADMIN_PASS

    # Appel de l'app pour créer l'admin si DB prête
    # (à customiser selon le projet : django createsuperuser, FastAPI init, etc.)

    # Affichage encart
    cat <<CRED

╔═══════════════════════════════════════════════════════╗
║                                                         ║
║  🔐 DEMO CREDENTIALS (auto-généré)                     ║
║                                                         ║
║    User     : $ADMIN_USER                              ║
║    Password : $ADMIN_PASS                              ║
║                                                         ║
║    URL      : ${APP_URL:-http://localhost:8000}       ║
║                                                         ║
║  ⚠️  NE PAS utiliser en production                     ║
║  ⚠️  Mot de passe régénéré à chaque démarrage si      ║
║     ADMIN_PASS non fourni                              ║
║                                                         ║
║  Pour utiliser un mot de passe fixe :                 ║
║    ADMIN_PASS=MonPass123 make demo                    ║
║                                                         ║
╚═══════════════════════════════════════════════════════╝

CRED
fi

# Continue avec l'entrypoint original si fourni
if [[ $# -gt 0 ]]; then
    exec "$@"
fi
