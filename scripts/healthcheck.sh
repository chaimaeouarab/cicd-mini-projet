#!/usr/bin/env bash
# Vérifie que /api/health répond 200 et que la version en service = tag attendu.
# Usage : healthcheck.sh <url> [tag_attendu]
set -uo pipefail

URL="$1"
EXPECTED="${2:-}"
TRIES=20

for i in $(seq 1 "$TRIES"); do
  CODE=$(curl -s -o /tmp/health.json -w '%{http_code}' --max-time 5 "$URL" || echo "000")
  [ "$CODE" = "200" ] && break
  echo "Tentative $i/$TRIES : HTTP $CODE, nouvel essai dans 3 s..."
  sleep 3
done

echo "Statut HTTP : $CODE"
echo "Réponse     : $(cat /tmp/health.json 2>/dev/null)"

if [ "$CODE" != "200" ]; then
  echo "::error::Le service ne répond pas 200"
  exit 1
fi

VERSION=$(jq -r '.version' /tmp/health.json)
echo "Version en service : $VERSION"

if [ -n "$EXPECTED" ] && [ "$VERSION" != "$EXPECTED" ]; then
  echo "::error::Version en service ($VERSION) différente du tag demandé ($EXPECTED)"
  exit 1
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Vérification après déploiement"
    echo "| Contrôle | Résultat |"
    echo "|---|---|"
    echo "| HTTP /api/health | $CODE |"
    echo "| Version en service | \`$VERSION\` |"
    echo "| Tag demandé | \`${EXPECTED:-n/a}\` |"
  } >> "$GITHUB_STEP_SUMMARY"
fi

echo "OK : service disponible, version $VERSION"
