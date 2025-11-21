# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker Compose-based infrastructure project for the Maakleerplek Soteria stack. It uses a modular architecture where individual services are defined in separate compose files under `services/` and then included into a root `docker-compose.yml`.

## Architecture

### Modular Service Structure

The project uses Docker Compose's `include` directive to compose multiple service definitions:

- **Root compose file**: `docker-compose.yml` - Defines the stack name and includes all service compose files
- **Service directories**: `services/<service-name>/` - Each service has its own directory containing:
  - `compose.yml` - Service-specific Docker Compose configuration
  - Service data directories (e.g., `db_data/`)

When you run `docker compose` commands at the root, Docker merges all included compose files into one unified configuration.

### Current Services

- **wikijs-wiki-prod-sot**: Wiki.js application with PostgreSQL database
  - Database service (`db`): PostgreSQL 15 Alpine
  - Wiki service (`wiki`): Wiki.js v2 (ghcr.io/requarks/wiki:2)
  - Exposed on port 3081 (maps to container port 3000)
  - Uses environment variables from `.env` for database credentials
  - Database data persisted to Docker volume: `/var/lib/docker/volumes/wikijs-wiki-prod-sot_wikidb-data/_data`

## Common Commands

### Running the Stack

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f wiki
docker compose logs -f db

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: destroys data)
docker compose down -v
```

### Managing Individual Services

```bash
# Restart a specific service
docker compose restart wiki

# View status of all services
docker compose ps

# Execute commands in a running container
docker compose exec wiki sh
docker compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

### Adding New Services

1. Create a new directory under `services/<service-name>/`
2. Create a `compose.yml` file defining the service
3. Add the service to the `include` list in the root `docker-compose.yml`:
   ```yaml
   include:
     - services/<service-name>/compose.yml
   ```

### Environment Variables

Services rely on `.env` files for configuration. The wikijs service requires:
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

Ensure `.env` files exist before starting services that require them.

## Infrastructure Notes

The `infrastructure/` directory is planned for Portainer setup and other infrastructure tooling (currently a TODO).
