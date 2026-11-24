#!/usr/bin/env bash
# Exécuté SUR l'instance EC2 (envoyé par SSH depuis le workflow deploy.yml).
# Usage : deploy.sh <image> <tag>   (GHCR_USER et GHCR_TOKEN dans l'environnement)
set -euo pipefail

IMAGE="$1"
TAG="$2"
NAME="cicd-app"

echo ">> Connexion à GHCR"
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

echo ">> Pull de $IMAGE:$TAG"
# On télécharge AVANT d'arrêter l'ancien conteneur : si le pull échoue,
# l'ancienne version reste en service.
docker pull "$IMAGE:$TAG"

echo ">> Remplacement du conteneur"
docker rm -f "$NAME" 2>/dev/null || true
docker run -d \
  --name "$NAME" \
  --restart unless-stopped \
  -p 80:3000 \
  "$IMAGE:$TAG"

docker logout ghcr.io >/dev/null
docker image prune -f >/dev/null || true

echo ">> Conteneur en service :"
docker ps --filter "name=$NAME" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
