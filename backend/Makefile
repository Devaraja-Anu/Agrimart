# Environment file
ENV_FILE := .env

# Directory containing Goose migration files
MIGRATIONS_DIR := ./migrations

.DEFAULT_GOAL := help

## run: run golang app
run:
	go run ./cmd/server/main.go --env=development

## test golang app
test:
	go test ./... -v

## help: show available commands
help:
	@echo "Usage:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed 's/^/ /'

# Verify Goose CLI is installed.
# Install:
#   go install github.com/pressly/goose/v3/cmd/goose@latest
check-goose:
	@command -v goose >/dev/null 2>&1 || \
	{ echo >&2 "❌ ERROR: goose is not installed."; \
	  echo >&2 "Install: go install github.com/pressly/goose/v3/cmd/goose@latest"; \
	  exit 1; }

# Validate database URL input.
check-url:
	@if [ -z "$(URL)" ]; then \
		echo "❌ ERROR: missing database URL"; \
		echo "Usage: make <target> URL=\"postgres://...\""; \
		exit 1; \
	fi

## migrate-create: create a new Goose SQL migration
migrate-create: check-goose
	@read -p "Enter migration name: " name; \
	goose -dir $(MIGRATIONS_DIR) -s create $$name sql

## migrate-up: apply all pending migrations
migrate-up: check-goose check-url
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" up

## migrate-down: rollback the most recent migration
migrate-down: check-goose check-url
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" down

## migrate-status: show migration status
migrate-status: check-goose check-url
	goose -dir $(MIGRATIONS_DIR) postgres "$(URL)" status