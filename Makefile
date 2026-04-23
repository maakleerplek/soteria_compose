.PHONY: up down pull deploy logs ps restart backup help

ENV_FILE := ./secrets/.env

## Start all services
up:
\tdocker compose --env-file $(ENV_FILE) up -d

## Stop all services (no data loss)
down:
\tdocker compose --env-file $(ENV_FILE) down

## Pull latest images
pull:
\tdocker compose --env-file $(ENV_FILE) pull

## Pull and restart — standard deploy
deploy: pull up

## Stream logs. Usage: make logs  or  make logs SERVICE=sot-prod-wiki-wikijs
logs:
\tdocker compose --env-file $(ENV_FILE) logs -f $(SERVICE)

## Show container status
ps:
\tdocker compose --env-file $(ENV_FILE) ps

## Restart a service. Usage: make restart SERVICE=sot-prod-wiki-wikijs
restart:
\tdocker compose --env-file $(ENV_FILE) restart $(SERVICE)

## Backup all data and secrets to TrueNAS
backup:
\trsync -az /var/lib/docker-compose/ hel-prod-nas-truenas:/mnt/pool/backups/soteria/var/lib/docker-compose/
\trsync -az ./secrets/.env hel-prod-nas-truenas:/mnt/pool/backups/soteria/secrets/

## Show this help
help:
\t@grep -E '^\#\#' Makefile | sed 's/\#\# //'
