#!/usr/bin/env bash
# À lancer UNE FOIS sur une instance EC2 neuve (Ubuntu 22.04/24.04) pour installer Docker.
# Usage : ssh -i cle.pem ubuntu@<IP> 'bash -s' < scripts/setup-ec2.sh
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y docker.io curl jq
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "Docker installé. Déconnectez-vous puis reconnectez-vous pour utiliser docker sans sudo."
docker --version || true
