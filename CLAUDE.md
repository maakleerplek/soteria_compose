# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker Compose-based infrastructure project for the Maakleerplek Soteria makerspace stack. It uses a modular architecture where individual services are defined in separate compose files under `services/` and included into a root [docker-compose.yml](docker-compose.yml). The stack is deployed and managed via Portainer for easy disaster recovery in a volunteer-based environment.

## Architecture

### Modular Service Structure

The project uses Docker Compose's `include` directive to compose multiple service definitions:

- **Root compose file**: [docker-compose.yml](docker-compose.yml) - Defines stack name (`sot-prod`) and includes all service compose files
- **Service directories**: `services/<service-name>/` - Each service has its own directory with:
  - `compose.yml` - Service-specific Docker Compose configuration
  - No local data storage (all data goes to `/docker_data/`)
- **Infrastructure**: [infrastructure/compose.yml](infrastructure/compose.yml) - Portainer container for stack management

When you run `docker compose` commands at the root, Docker merges all included compose files into one unified configuration.

### Data and Secrets Management

- **All persistent data**: `/docker_data/` - Single directory containing all service data and Portainer configuration, backed up to NAS
- **Secrets**: `./env` - Environment variables for all services, excluded from Git (see [.gitignore](.gitignore)), backed up to NAS and stored in Bitwarden
- **Configuration**: All `compose.yml` files are version-controlled in Git

### Deployment Flow

The intended deployment model is:
1. Developer commits changes to Git
2. Push to GitHub
3. Portainer pulls and redeploys from the repository
4. Services update automatically

For disaster recovery, the entire stack can be rebuilt from Git + NAS backups.

## Current Services

All services use timezone `Europe/Brussels`.

### sot-prod-proxy-nginx
- **Image**: `jc21/nginx-proxy-manager:latest`
- **Purpose**: Reverse proxy with Let's Encrypt SSL
- **Ports**: 80 (HTTP), 81 (admin UI), 443 (HTTPS)
- **Data**: `/docker_data/sot-prod-proxy-nginx_data`, `/docker_data/sot-prod-proxy-nginx_letsencrypt`

### sot-prod-wiki-wikijs
- **Image**: `ghcr.io/requarks/wiki:2` + PostgreSQL 15 Alpine
- **Purpose**: Wiki.js documentation platform
- **Ports**: 3081 → 3000
- **Services**: `wiki` (app), `wikidb` (database)
- **Data**: `/docker_data/sot-prod-wiki-wikijs-wikidb_data`, `/docker_data/sot-prod-wiki-wikijs-wiki_data_content`
- **Secrets**: `WIKI_POSTGRES_DB`, `WIKI_POSTGRES_USER`, `WIKI_POSTGRES_PASSWORD`

### sot-prod-auth-keycloak
- **Image**: `quay.io/keycloak/keycloak:24.0.5` + PostgreSQL 15 Alpine
- **Purpose**: Identity and access management (SSO)
- **Ports**: 8080
- **Services**: `keycloak` (app), `keycloakdb` (database)
- **Data**: `/docker_data/sot-prod-auth-keycloak-postgres_data`, `/docker_data/sot-prod-auth-keycloak_data`
- **Secrets**: `KEYCLOAK_DB_NAME`, `KEYCLOAK_DB_USER`, `KEYCLOAK_DB_PASSWORD`, `KEYCLOAK_ADMIN_USER`, `KEYCLOAK_ADMIN_PASSWORD`, `KEYCLOAK_HOSTNAME`
- **Note**: Running in `start-dev` mode with `KC_PROXY=edge` for reverse proxy compatibility

### soft-prod-adguard
- **Image**: `adguard/adguardhome`
- **Purpose**: Network-wide ad blocking and DNS
- **Ports**: 53 (DNS TCP/UDP), 5350 (web UI HTTP), 5443 (web UI HTTPS), 853 (DNS over TLS), 784 (DNS over QUIC), 3082 (alternate web UI)
- **Data**: `/docker_data/soft-prod-adguard/work`, `/docker_data/soft-prod-adguard/conf`

### Infrastructure: Portainer
- **Image**: `portainer/portainer-ce:lts`
- **Location**: [infrastructure/compose.yml](infrastructure/compose.yml)
- **Purpose**: Docker GUI management
- **Ports**: 9443 (HTTPS UI), 8000 (HTTP UI)
- **Data**: `/docker_data/sot-prod-portainer`
- **Special**: Mounts Docker socket for container management

## Common Commands

### Running the Stack

```bash
# Start all services (from root directory)
docker compose up -d

# View all logs
docker compose logs -f

# View logs for specific service
docker compose logs -f wiki
docker compose logs -f keycloak

# View service status
docker compose ps

# Stop all services
docker compose down

# Stop and remove volumes (⚠️  DESTROYS DATA)
docker compose down -v
```

### Managing Individual Services

```bash
# Restart a service
docker compose restart wiki

# Update a service (pull latest image and recreate)
docker compose pull wiki
docker compose up -d wiki

# Force recreate without pulling
docker compose up -d --force-recreate wiki

# Execute commands in a running container
docker compose exec wiki sh
docker compose exec wikidb psql -U ${WIKI_POSTGRES_USER} -d ${WIKI_POSTGRES_DB}
docker compose exec keycloak sh
```

### Portainer Management

```bash
# Deploy Portainer (from infrastructure directory)
cd infrastructure
docker compose up -d

# View Portainer logs
docker compose logs -f portainer

# Access Portainer UI
# Navigate to http://<server-ip>:8000 or https://<server-ip>:9443
```

### Data Backup and Restore

```bash
# Backup all service data to NAS (single command backs up everything)
rsync -avz /docker_data/ nas:/backups/docker_data/

# Backup secrets separately
rsync -avz ./secrets/.env nas:/backups/secrets/

# Restore all data from NAS
rsync -avz nas:/backups/docker_data/ /docker_data/

# Restore secrets
mkdir -p ./secrets
rsync -avz nas:/backups/secrets/.env ./secrets/.env
```

## Adding New Services

### Step-by-Step Process

1. **Create service directory structure**:
   ```bash
   mkdir -p services/<service-name>
   ```

2. **Create [compose.yml](services/<service-name>/compose.yml)** with this pattern:
   ```yaml
   services:
     myservice:
       image: <image-name>:<tag>
       container_name: <service-name>
       environment:
         # Use secrets from ./secrets/.env
         SOME_VAR: ${ENV_VAR_NAME}
         TZ: 'Europe/Brussels'
       volumes:
         # Store ALL data in /docker_data/<service-name>/
         - /docker_data/<service-name>:/app/data
       ports:
         - "<host-port>:<container-port>"
       restart: unless-stopped
   ```

3. **Add to root [docker-compose.yml](docker-compose.yml)**:
   ```yaml
   include:
     - services/<service-name>/compose.yml
   ```

4. **Add secrets to `./secrets/.env`** (if needed):
   ```bash
   # Service: <service-name>
   ENV_VAR_NAME=secret_value
   ```

5. **Test locally**:
   ```bash
   docker compose up -d <service-name>
   docker compose logs -f <service-name>
   ```

6. **Commit and push**:
   ```bash
   git add services/<service-name>/ docker-compose.yml
   git commit -m "Add <service-name> service"
   git push
   ```

7. **Update in Portainer**:
   - Navigate to Stacks → sot-prod → "Pull and redeploy"

### Important Conventions

- **Naming**: Use pattern `<prefix>-prod-<purpose>-<software>` (e.g., `sot-prod-wiki-wikijs`)
- **Container names**: Match service directory name for consistency
- **Data paths**: Always use `/docker_data/<service-name>/` for volumes
- **Timezone**: Set `TZ: 'Europe/Brussels'` for all services
- **Restart policy**: Use `restart: unless-stopped` for all services
- **Dependencies**: Use `depends_on` for services that require other services (e.g., web app depends on database)

## Secrets Management

All secrets are stored in `./env` (not committed to Git). This file is sourced by Docker Compose and should contain:

```bash
# Wiki.js
WIKI_POSTGRES_DB=wiki
WIKI_POSTGRES_USER=wikijs
WIKI_POSTGRES_PASSWORD=<secret>

# Keycloak
KEYCLOAK_DB_NAME=keycloak
KEYCLOAK_DB_USER=keycloak
KEYCLOAK_DB_PASSWORD=<secret>
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=<secret>
KEYCLOAK_HOSTNAME=auth.example.com

# Add new service secrets below...
```

Secrets are also backed up to:
- NAS: `nas:/backups/env`
- Bitwarden: For redundancy and team access

## Troubleshooting

### Service won't start

```bash
# Check logs
docker compose logs <service-name>

# Check if container exists
docker ps -a | grep <service-name>

# Check if port is in use
netstat -tlnp | grep <port>

# Verify secrets exist
cat ./secrets/.env | grep <VARIABLE>
```

### Port conflicts

If a port is already in use, either:
- Stop the conflicting service
- Change the host port in the service's `compose.yml` (left side of `<host>:<container>`)

### Data not persisting

```bash
# Verify volume mounts
docker inspect <container-name> | grep Mounts -A 20

# Check permissions on /docker_data/
ls -la /docker_data/

# Verify directory exists
ls -la /docker_data/<service-name>/
```

### Portainer can't pull from Git

- Verify Git repository URL is correct
- Check if repository is public (or add deploy keys)
- Ensure network connectivity from server

## Disaster Recovery

See the [README.md](README.md#-panic-disaster-recovery) for complete disaster recovery procedures. The quick version:

1. Install Docker on fresh server
2. Restore `/docker_data/` from NAS backup
3. Restore `./secrets/.env` from NAS or Bitwarden
4. Deploy Portainer: `cd infrastructure && docker compose up -d`
5. Access Portainer and pull stack from Git (if fresh install)
6. Verify all services: `docker compose ps`
