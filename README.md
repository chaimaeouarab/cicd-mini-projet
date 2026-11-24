# Mini-projet CI/CD — GitHub Actions → GHCR → EC2

Chaîne qui teste une application Node.js, publie une image Docker versionnée dans
GitHub Container Registry (GHCR) et déploie sur Amazon EC2 la version choisie.

## Architecture

```
 push dev/main ──► CI (ci.yml)
                    ├─ job test     : npm ci + npm test
                    └─ job publish  : (main + tests OK) build + push ghcr.io/<owner>/<repo>:sha-xxxxxxx

 lancement manuel ──► Deploy (deploy.yml, input "tag")
                    ├─ vérifie que l'image existe dans GHCR
                    ├─ SSH vers EC2 → scripts/deploy.sh (pull + remplacement du conteneur)
                    └─ scripts/healthcheck.sh : HTTP 200 sur /api/health + version == tag
```

| Élément | Choix |
|---|---|
| Tag d'image | `sha-<7 premiers caractères du commit>` → retrouve le commit d'origine |
| Preuve de version | `APP_VERSION` gravé dans l'image au build, renvoyé par `/api/health` |
| Concurrence | `concurrency: deploy-ec2-production`, `cancel-in-progress: false` |
| Secrets | `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY`, `GHCR_USER`, `GHCR_TOKEN` |

## Structure

```
src/app.js, src/server.js     Application Express (/api/health, /api/add)
tests/app.test.js             Tests Jest + Supertest
Dockerfile                    Image node:20-alpine, ARG APP_VERSION
.github/workflows/ci.yml      Tests + publication GHCR
.github/workflows/deploy.yml  Déploiement manuel sur EC2
scripts/deploy.sh             Exécuté sur EC2 (pull + run)
scripts/healthcheck.sh        Contrôle HTTP + version
scripts/setup-ec2.sh          Installation de Docker sur une EC2 neuve
docs/Jenkinsfile.example      Transposition Jenkins
```

## Lancer en local

```bash
npm install
npm test
npm start                     # http://localhost:3000/api/health
docker build --build-arg APP_VERSION=local -t cicd-app .
docker run -p 3000:3000 cicd-app
```

## Relancer la chaîne

1. **Secrets** (Settings → Secrets and variables → Actions) :
   `EC2_HOST` (IP publique), `EC2_USER` (`ubuntu`), `EC2_SSH_KEY` (contenu du .pem),
   `GHCR_USER` (login GitHub), `GHCR_TOKEN` (PAT avec `read:packages`).
2. **Environnement** : Settings → Environments → créer `production`.
3. **EC2** : Ubuntu, Security Group ouvert en 22 et 80, puis
   `ssh -i cle.pem ubuntu@<IP> 'bash -s' < scripts/setup-ec2.sh`.
4. **CI** : push sur `main` → l'onglet Actions publie `sha-xxxxxxx` dans Packages.
5. **Déploiement** : Actions → *Deploy - EC2 (manuel)* → *Run workflow* → saisir le tag.
6. **Vérification** : `curl http://<IP>/api/health` → `{"status":"ok","version":"sha-xxxxxxx",...}`.

## Scénarios de démonstration

| Scénario | Comment le reproduire | Preuve attendue |
|---|---|---|
| Échec de test | Push sur main d'un test cassé | job `test` rouge, job `publish` *skipped* |
| V1 puis V2 | Déployer V1, pousser V2 sur main sans déployer | `/api/health` montre toujours V1 jusqu'au déploiement manuel de V2 |
| Restauration | Relancer Deploy avec le tag V1 | HTTP 200 et `version` = tag V1 |
