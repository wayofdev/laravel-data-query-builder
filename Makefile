-include .env

# BuildKit enables higher performance docker builds and caching possibility
# to decrease build times and increase productivity for free.
# https://docs.docker.com/compose/environment-variables/envvars/
export DOCKER_BUILDKIT ?= 1

# Binary to use, when executing docker-compose tasks
DOCKER_COMPOSE ?= docker compose

# Support image with all needed binaries, like envsubst, mkcert, wait4x
SUPPORT_IMAGE ?= wayofdev/build-deps:alpine-latest

APP_RUNNER ?= $(DOCKER_COMPOSE) run --rm --no-deps app
APP_COMPOSER ?= $(APP_RUNNER) composer

BUILDER_PARAMS ?= docker run --rm -i \
	--env-file ./.env \
	--env COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) \
	--env COMPOSER_AUTH="$(COMPOSER_AUTH)"

BUILDER ?= $(BUILDER_PARAMS) $(SUPPORT_IMAGE)
BUILDER_WIRED ?= $(BUILDER_PARAMS) --network project.$(COMPOSE_PROJECT_NAME) $(SUPPORT_IMAGE)

# Shorthand envsubst command, executed through build-deps
ENVSUBST ?= $(BUILDER) envsubst

NPM_RUNNER ?= pnpm

# https://phpstan.org/user-guide/output-format
export PHPSTAN_OUTPUT_FORMAT ?= table

EXPORT_VARS = '\
	$${COMPOSE_PROJECT_NAME} \
	$${COMPOSER_AUTH}'

# Self documenting Makefile code
# ------------------------------------------------------------------------------------
ifneq ($(TERM),)
	BLACK := $(shell tput setaf 0)
	RED := $(shell tput setaf 1)
	GREEN := $(shell tput setaf 2)
	YELLOW := $(shell tput setaf 3)
	LIGHTPURPLE := $(shell tput setaf 4)
	PURPLE := $(shell tput setaf 5)
	BLUE := $(shell tput setaf 6)
	WHITE := $(shell tput setaf 7)
	RST := $(shell tput sgr0)
else
	BLACK := ""
	RED := ""
	GREEN := ""
	YELLOW := ""
	LIGHTPURPLE := ""
	PURPLE := ""
	BLUE := ""
	WHITE := ""
	RST := ""
endif
MAKE_LOGFILE = /tmp/wayofdev-laravel-data-query-builder.log
MAKE_CMD_COLOR := $(BLUE)

default: all

help:
	@echo 'Management commands for package:'
	@echo 'Usage:'
	@echo '    ${MAKE_CMD_COLOR}make${RST}                       Setups dependencies for fresh-project, like composer install, git hooks and others...'
	@grep -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    ${MAKE_CMD_COLOR}make %-21s${RST} %s\n", $$1, $$2}'
	@echo
	@echo '    📑 Logs are stored in      $(MAKE_LOGFILE)'
	@echo
	@echo '    📦 Package                 laravel-data-query-builder (github.com/wayofdev/laravel-data-query-builder)'
	@echo '    🤠 Author                  Andrij Orlenko (github.com/lotyp)'
	@echo '    🏢 ${YELLOW}Org                     wayofdev (github.com/wayofdev)${RST}'
.PHONY: help

.EXPORT_ALL_VARIABLES:


# Default action
# Defines default command when `make` is executed without additional parameters
# ------------------------------------------------------------------------------------
all: install hooks
.PHONY: all


# System Actions
# ------------------------------------------------------------------------------------
env: ## Generate .env file from example, use `make env force=true`, to force re-create file
ifeq ($(FORCE),true)
	@echo "${YELLOW}Force re-creating .env file from example...${RST}"
	$(ENVSUBST) $(EXPORT_VARS) < ./.env.example > ./.env
else ifneq ("$(wildcard ./.env)","")
	@echo ""
	@echo "${YELLOW}The .env file already exists! Use FORCE=true to re-create.${RST}"
else
	@echo "Creating .env file from example"
	$(ENVSUBST) $(EXPORT_VARS) < ./.env.example > ./.env
endif
.PHONY: env

prepare:
	mkdir -p .build/php-cs-fixer
.PHONY: prepare


# Docker Actions
# ------------------------------------------------------------------------------------
up: # Creates and starts containers, defined in docker-compose and override file
	$(DOCKER_COMPOSE) up --remove-orphans -d
.PHONY: up

down: # Stops and removes containers of this project
	$(DOCKER_COMPOSE) down --remove-orphans --volumes
.PHONY: down

restart: down up ## Runs down and up commands
.PHONY: restart

clean: ## Stops containers if required and removes from system
	$(DOCKER_COMPOSE) rm --force --stop
.PHONY: clean

ps: ## List running project containers
	$(DOCKER_COMPOSE) ps
.PHONY: ps

logs: ## Show project docker logs with follow up mode enabled
	$(DOCKER_COMPOSE) logs -f
.PHONY: logs

pull: ## Pull and update docker images in this project
	$(DOCKER_COMPOSE) pull
.PHONY: pull

ssh: ## Login inside running docker container
	$(APP_RUNNER) sh
.PHONY: ssh


# Composer
# ------------------------------------------------------------------------------------
install: ## Installs composer dependencies
	$(APP_COMPOSER) install
.PHONY: install

update: ## Updates composer dependencies by running composer update command
	$(APP_COMPOSER) update
.PHONY: update


# Code Quality, Git, Linting, Testing
# ------------------------------------------------------------------------------------
hooks: ## Install git hooks from pre-commit-config
	pre-commit install
	pre-commit autoupdate
.PHONY: hooks

lint: lint-yaml lint-php lint-stan ## Runs all linting commands
.PHONY: lint

lint-yaml: ## Lints yaml files inside project
	yamllint .
.PHONY: lint-yaml

lint-php: prepare ## Fixes code to follow coding standards using php-cs-fixer
	$(APP_COMPOSER) cs:fix
.PHONY: lint-php

lint-diff: prepare ## Runs php-cs-fixer in dry-run mode and shows diff which will by applied
	$(APP_COMPOSER) cs:diff
.PHONY: lint-diff

lint-stan: ## Runs phpstan – static analysis tool
	$(APP_COMPOSER) stan
.PHONY: lint-stan

lint-stan-ci:
	$(APP_COMPOSER) stan:ci
.PHONY: lint-stan-ci

test: ## Run project php-unit and pest tests
	$(APP_COMPOSER) test
.PHONY: test

test-cc: ## Run project php-unit and pest tests in coverage mode and build report
	$(APP_COMPOSER) test:cc
.PHONY: test-cc

# Documentation
# ------------------------------------------------------------------------------------
docs-deps-update: ## Check for outdated dependencies and automatically update them using pnpm
	cd docs && $(NPM_RUNNER) run deps:update
.PHONY: docs-deps-update

docs-deps-install: ## Install dependencies for documentation using pnpm
	cd docs && $(NPM_RUNNER) install
.PHONY: docs-deps-install

docs-up: ## Start documentation server
	cd docs && $(NPM_RUNNER) dev
.PHONY: docs-up
