# Environment file
ENV_FILE := .env
# Load .env if it exists
-include $(ENV_FILE)
export $(shell sed 's/=.*//' $(ENV_FILE))

# Directory containing Goose migration files
MIGRATIONS_DIR := ./migrations
# Directory containing seed SQL files
SEEDS_DIR := ./migrations/seeds
# Use DATABASE_URL from .env unless URL is passed explicitly
URL ?= $(DATABASE_URL)

# Helper to run psql commands inside the container
DOCKER_DB_CMD := docker exec -i agrimart_db

.DEFAULT_GOAL := help

## run: run golang app
run:
	go run ./cmd/server/main.go --env=development

## test: test golang app
test:
	go test ./... -v

## help: show available commands
help:
	@echo "Usage:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed 's/^/ /'

# Verify tools are installed
check-goose:
	@command -v goose >/dev/null 2>&1 || { echo "❌ ERROR: goose is not installed. Install: go install github.com/pressly/goose/v3/cmd/goose@latest"; exit 1; }

# Validate database URL is set
check-url:
	@if [ -z "$(URL)" ]; then \
		echo "❌ ERROR: missing database URL. Set DATABASE_URL in .env or pass URL='...'"; \
		exit 1; \
	fi

## migrate-create: create a new Goose SQL migration
migrate-create: check-goose
	@read -p "Enter migration name: " name; \
	goose -dir $(MIGRATIONS_DIR) -s create $$name sql

## migrate-up: apply all pending migrations
migrate-up: check-goose check-url wait-db
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" up

## migrate-down: rollback the most recent migration
migrate-down: check-goose check-url wait-db
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" down

## migrate-status: show migration status
migrate-status: check-goose check-url
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" status

## migrate-reset: rollback all migrations then re-apply (dev only)
migrate-reset: check-goose check-url wait-db
	@read -p "⚠️  Are you sure you want to drop the database? [y/N] " confirm && [ "$$confirm" = "y" ]
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" reset

wait-db:
	@echo "⏳ waiting for postgres..."
	@until docker exec agrimart_db pg_isready -U $(POSTGRES_USER) -d $(POSTGRES_DB) > /dev/null 2>&1; do \
		sleep 1; \
	done
	@echo "✅ postgres is ready"

## seed: run all seed scripts in order
seed: wait-db
	@for f in $(SEEDS_DIR)/*.sql; do \
		[ -e "$$f" ] || continue; \
		echo "▶ seeding $$f"; \
		$(DOCKER_DB_CMD) psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -f "$$f" || exit 1; \
	done

## fresh: reset migrations and re-seed (dev only)
fresh: wait-db migrate-reset migrate-up seed @echo "Fresh database ready."