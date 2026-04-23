# Soteria Stack

Reproducible Docker infrastructure for Soteria (Rocky Linux 9.5 — firewall & network gateway).

## Architecture

```
Soteria (sot) — network boundary, access control
  ├── sot-prod-proxy-nginx       Reverse proxy + SSL termination (NPM)
  ├── sot-prod-auth-authentik    Identity provider / SSO (+ db, worker)
  ├── sot-prod-wiki-wikijs       Internal knowledge base (+ db)
  └── sot-prod-dns-adguard       DNS + ad-blocking
```

## Data Management

- **All persistent data**: `/var/lib/docker-compose/` — backed up to TrueNAS
- **Secrets**: `./secrets/.env` — excluded from Git, backed up to TrueNAS + stored in Bitwarden
- **Configuration**: all `compose.yml` files — version controlled here

## Common Operations

```bash
make deploy       # pull latest images + start all services
make up           # start all services (no pull)
make down         # stop all services (no data loss)
make ps           # show container status
make logs         # stream all logs
make logs SERVICE=sot-prod-wiki-wikijs   # stream logs for one service
make restart SERVICE=sot-prod-auth-authentik-server
make backup       # rsync data + secrets to TrueNAS
```

## 🚨 Disaster Recovery

1. **Install Rocky Linux 9.5, install Docker**
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker $USER
   ```
2. **Clone this repo**
   ```bash
   git clone https://github.com/maakleerplek/soteria_compose /opt/stacks/soteria-compose
   cd /opt/stacks/soteria-compose
   ```
3. **Restore data from TrueNAS**
   ```bash
   rsync -az hel-prod-nas-truenas:/mnt/pool/backups/soteria/var/lib/docker-compose/ /var/lib/docker-compose/
   ```
4. **Restore secrets**
   ```bash
   rsync -az hel-prod-nas-truenas:/mnt/pool/backups/soteria/secrets/.env ./secrets/.env
   # Or retrieve from Bitwarden
   ```
5. **Deploy**
   ```bash
   make up
   ```
6. **Verify**
   ```bash
   make ps
   make logs
   ```

## Adding a New Service

1. Create `services/sot-prod-{role}-{app}/compose.yml`
2. Follow conventions in CLAUDE.md
3. Add the include line to root `docker-compose.yml`
4. Add secrets to `secrets/.env` and update `secrets/.env.example`
5. `make deploy`
6. Commit and push

## Current Services

| Service | Role | Port | Notes |
|---|---|---|---|
| `sot-prod-proxy-nginx` | Reverse proxy + SSL | 80, 443 | Front door for all web services |
| `sot-prod-auth-authentik` | SSO / identity provider | 9080, 9444 | Proxies Azure OIDC |
| `sot-prod-wiki-wikijs` | Internal wiki | 3081 | |
| `sot-prod-dns-adguard` | DNS + ad-blocking | 53, 5350 | |

## Planned Services

| Service | Role |
|---|---|
| `sot-prod-access-teleport` | SSH bastion (Teleport Auth + Proxy) |
