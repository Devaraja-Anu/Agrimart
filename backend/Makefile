# Environment file
ENV_FILE := .env
-include $(ENV_FILE)
export $(shell sed 's/=.*//' $(ENV_FILE))

# Configuration
MIGRATIONS_DIR := ./migrations
SEEDS_DIR := ./migrations/seeds
URL ?= $(DATABASE_URL)
DC := docker compose

.DEFAULT_GOAL := help


## run: run main.go
run:
	go run ./cmd/server


## help: show available commands
help:
	@echo "Usage:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed 's/^/ /'

## up: start services in the background
up:
	$(DC) up -d

## down: stop services
down:
	$(DC) down

## wait: wait for the database container to be healthy
wait:
	@echo "Waiting for database to report healthy status..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' agrilib_db)" = "healthy" ]; do \
		echo "Database starting... (current status: $$(docker inspect -f '{{.State.Health.Status}}' agrilib_db))"; \
		sleep 2; \
	done
	@echo "Database is healthy and ready!"
	
## check-goose: verify goose is installed
check-goose:
	@command -v goose >/dev/null 2>&1 || { echo "ERROR: goose is not installed."; exit 1; }

## check-url: verify URL is present
check-url:
	@if [ -z "$(URL)" ]; then \
		echo "ERROR: missing DATABASE_URL"; \
		exit 1; \
	fi

## migrate-create: create a new migration
migrate-create: check-goose
	@read -p "Enter migration name: " name; \
	goose -dir $(MIGRATIONS_DIR) -s create $$name sql


## migrate-up: apply all pending migrations
migrate-up: check-goose check-url wait
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" up

## migrate-down: rollback the most recent migration
migrate-down: check-goose check-url wait
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" down

## migrate-reset: rollback all then re-apply
migrate-reset: check-goose check-url wait
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" reset

## migrate-status: show migration status
migrate-status: check-goose check-url wait
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" status

## seed: run all seed scripts in order
seed: wait
	@for f in $(SEEDS_DIR)/*.sql; do \
		[ -e "$$f" ] || continue; \
		echo "seeding $$f"; \
		docker exec -i agrilib_db \
			psql -v ON_ERROR_STOP=1 \
			-U $(POSTGRES_USER) \
			-d $(POSTGRES_DB) < "$$f" || exit 1; \
	done


## fresh: reset, migrate, and seed
fresh: migrate-reset migrate-up seed
	@echo "Database is fresh and seeded."