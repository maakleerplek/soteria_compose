# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

Docker Compose infrastructure for Soteria — Rocky Linux 9.5 server acting as the network boundary and access control layer for Maakleerplek. Mirrors the structure of helios-compose.

Only network-boundary and access-control services live here. No user apps.

## Architecture

Modular structure using Docker Compose `include`:
- **Root** `docker-compose.yml` — stack name + include list
- **`services/{service-name}/compose.yml`** — one directory per service
- **`secrets/.env`** — all secrets, git-ignored, backed up to TrueNAS + Bitwarden
- **`/docker_data/`** — all persistent data on the host, backed up to TrueNAS

## Naming Convention

Pattern: `{server}-{env}-{role}-{app}`

| Part | Values |
|---|---|
| server | `sot` (Soteria) |
| env | `prod` |
| role | `proxy`, `auth`, `wiki`, `dns`, `access` |
| app | `nginx`, `authentik`, `wikijs`, `adguard`, `teleport` |

Examples: `sot-prod-proxy-nginx`, `sot-prod-auth-authentik`, `sot-prod-dns-adguard`

Sub-services (databases, workers) append a suffix: `sot-prod-auth-authentik-db`, `sot-prod-wiki-wikijs-db`

Container names must match the service key exactly.

## Conventions for compose.yml files

```yaml
services:
  sot-prod-{role}-{app}:
    image: vendor/image:pinned-version     # pin versions, don't use latest in prod
    container_name: sot-prod-{role}-{app}  # always set, matches service key
    restart: unless-stopped
    environment:
      TZ: 'Europe/Brussels'                # always set timezone
      SOME_SECRET: ${ENV_VAR}              # reference secrets/.env via ${}
    volumes:
      - /docker_data/sot-prod-{role}-{app}:/app/data   # always /docker_data/
    ports:
      - host:container
```

## Secrets

All in `secrets/.env`. Never committed to Git.
- Template: `secrets/.env.example` (committed, no real values)
- Backup: TrueNAS `/mnt/pool/backups/soteria/secrets/` + Bitwarden

## Data

All volumes use `/docker_data/{container-name}/` on the host. One rsync backs up everything:
```bash
rsync -az /docker_data/ hel-prod-nas-truenas:/mnt/pool/backups/soteria/docker_data/
```

## Deployment

No Portainer. All operations via `make` or direct `docker compose` commands.

```bash
make deploy                                    # standard deploy: pull + up
make logs SERVICE=sot-prod-auth-authentik-server   # tail logs for one service
docker compose exec sot-prod-wiki-wikijs sh   # shell into container
```

## What belongs here

Only services that form the network boundary or control access:
- Reverse proxy (NPM)
- Identity provider (Authentik)
- DNS (AdGuard)
- SSH bastion (Teleport, planned)
- Internal knowledge base (Wiki.js — exception, hosted here for simplicity)

Everything else lives on Helios in helios-compose or is managed by Coolify.
