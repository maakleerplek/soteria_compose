.PHONY: up down pull deploy logs ps restart backup help

ENV_FILE := ./secrets/.env

## Start all services
up:
	docker compose --env-file $(ENV_FILE) up -d

## Stop all services (no data loss)
down:
	docker compose --env-file $(ENV_FILE) down

## Pull latest images
pull:
	docker compose --env-file $(ENV_FILE) pull

## Pull and restart — standard deploy
deploy: pull up

## Stream logs. Usage: make logs  or  make logs SERVICE=sot-prod-wiki-wikijs
logs:
	docker compose --env-file $(ENV_FILE) logs -f $(SERVICE)

## Show container status
ps:
	docker compose --env-file $(ENV_FILE) ps

## Restart a service. Usage: make restart SERVICE=sot-prod-wiki-wikijs
restart:
	docker compose --env-file $(ENV_FILE) restart $(SERVICE)

## Backup all data and secrets to TrueNAS
backup:
	rsync -az /var/lib/docker-compose/ hel-prod-nas-truenas:/mnt/pool/backups/soteria/var/lib/docker-compose/
	rsync -az ./secrets/.env hel-prod-nas-truenas:/mnt/pool/backups/soteria/secrets/

## Show this help
help:
	@grep -E '^\#\#' Makefile | sed 's/\#\# //'
