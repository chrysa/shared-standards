#!make
# ============================================================================
# BASE VARIABLES (no dependencies)
# ============================================================================

# Backoffice
BACKOFFICE_BASE_URL ?= http://0.0.0.0:3002
BACKOFFICE_FOLDER ?= ../padam-av-backoffice

# Dependencies check
REQUIRED_SYSTEM_TOOLS := git docker pip pre-commit gh
REQUIRED_SYSTEM_TOOLS_APT_PACKAGES := git=git docker=docker.io pip=python3-pip pre-commit=pre-commit gh=gh

# Bootstrap folder
BOOTSTRAP_FOLDER ?= /entrypoints/bootstraped

# Secrets source of truth
SECRETS_YAML_FILE ?= secrets.yaml

# Database secrets
DATABASE_HOST ?= $(shell if [ -f "${SECRETS_YAML_FILE}" ]; then sed -n -E 's/^[[:space:]]*database-host:[[:space:]]*//p' "${SECRETS_YAML_FILE}" | tail -1 | sed -E "s/^['\"](.*)['\"]$$/\1/"; elif [ -f docker/secrets/database-host.txt ]; then cat docker/secrets/database-host.txt; fi)
DATABASE_PASSWORD ?= $(shell if [ -f "${SECRETS_YAML_FILE}" ]; then sed -n -E 's/^[[:space:]]*database-password:[[:space:]]*//p' "${SECRETS_YAML_FILE}" | tail -1 | sed -E "s/^['\"](.*)['\"]$$/\1/"; elif [ -f docker/secrets/database-password.txt ]; then cat docker/secrets/database-password.txt; fi)
DATABASE_PORT ?= $(shell if [ -f "${SECRETS_YAML_FILE}" ]; then sed -n -E 's/^[[:space:]]*database-port:[[:space:]]*//p' "${SECRETS_YAML_FILE}" | tail -1 | sed -E "s/^['\"](.*)['\"]$$/\1/"; elif [ -f docker/secrets/database-port.txt ]; then cat docker/secrets/database-port.txt; fi)
DATABASE_USERNAME ?= $(shell if [ -f "${SECRETS_YAML_FILE}" ]; then sed -n -E 's/^[[:space:]]*database-username:[[:space:]]*//p' "${SECRETS_YAML_FILE}" | tail -1 | sed -E "s/^['\"](.*)['\"]$$/\1/"; elif [ -f docker/secrets/database-username.txt ]; then cat docker/secrets/database-username.txt; fi)

# Default versions
DEFAULT_SWAGGER_VERSION ?= v1

# Django
DJANGO_LOG_LEVEL ?= INFO
DJANGO_MANAGE_PY ?= python manage.py
DJANGO_SUPERUSER_EMAIL ?= root@root.root
DJANGO_SUPERUSER_PASSWORD ?= rootrootroot
DJANGO_SUPERUSER_USERNAME ?= root
DJANGO_VERBOSITY ?= 3

# Docker base
DOCKER_COMPOSE_ARGS ?=
DOCKER_COMPOSE_CMD := docker compose -f docker-compose.yml
DOCKER_RUN_ARGS := --rm --interactive
DOCKER_RUN_COMMON_ARGS := --rm --entrypoint="bash"
DOCKER_RUN_ENV := --env DJANGO_VERBOSITY=${DJANGO_VERBOSITY} --env DJANGO_LOG_LEVEL=${DJANGO_LOG_LEVEL}
DOCKER_RUN_WORK_DIR := -w /code
docker_repo ?= harbor.tech.padam.io/padam/av

# Front
FRONT_BASE_URL ?= http://0.0.0.0:3000
FRONT_FOLDER = ../padam-av-supervision-interface

# Git
GIT_BRANCH=$(shell git branch --show-current | cut -d'/' -f2 | sed -E "s;/;-;g" | sed -E "s;\#;;g" | head -c 40)
GIT_BRANCH_LONG=$(shell git branch --show-current | cut -d'/' -f2 | sed -E "s;/;-;g" | sed -E "s;\#;;g")

# Padam base directories
PADAM_APP_DIR ?= padam_av
PADAM_APP_NAME ?= padam_av
PADAM_CONFIG_DIR ?= config
PADAM_DEBUG ?= true
PADAM_DOCS_DIR ?= docs
PADAM_ENV ?= dev
PADAM_LOG_LEVEL ?= DEBUG
PADAM_REPORTS_DIR ?= reports
PADAM_SECRETS_DIR ?= secrets

# Padam Git
PADAM_GIT_EMAIL ?= $(shell git config user.email)
PADAM_GIT_USER ?= $(shell git config user.name)

# Palomata
PALOMATA_CONTAINER_API = http://palomata_backend:8102
PALOMATA_FOLDER = ../padam-av-simul
PALOMATA_TRAINING_API = http://api.palomata.av.demo.padam.io

# Pre-commit
PRE_COMMIT_CMD := pre-commit

# Pull request
pr_assignee ?= ${PADAM_GIT_USER}
pr_reviewer ?= dev-av
pr_target ?= develop

# Protobuf
PROTOBUF_SERVICE_NAME=protobuf

# Server
SERVER_BASE_URL ?= http://0.0.0.0:8888

# ============================================================================
# DERIVED VARIABLES (depend on base variables)
# ============================================================================

# App paths (depends on PADAM_APP_DIR via app_path)
app_path ?= apps
app_consumer_path ?= ${app_path}/consumer
app_provider_path ?= ${app_path}/provider

# Bootstrap file (depends on BOOTSTRAP_FOLDER, GIT_BRANCH)
BOOTSTRAPED_FILE=${BOOTSTRAP_FOLDER}/$(shell echo ${GIT_BRANCH} | sed 's;/;-;')

# Database name (depends on GIT_BRANCH)
DATABASE_NAME=padam_av-${GIT_BRANCH}

# Django settings (depends on PADAM_ENV)
DJANGO_SETTINGS_MODULE ?= padam_av.settings.${PADAM_ENV:-LOCAL}

# Docker compose base (depends on DOCKER_COMPOSE_CMD, DOCKER_COMPOSE_ARGS)
__docker_compose_project_base_command := ${DOCKER_COMPOSE_CMD} ${DOCKER_COMPOSE_ARGS}

# Documentation folders
documentation_required_files_and_folder = docs/

# Mobile Thinking & Navya paths (depends on app_provider_path)
MOBILE_THINKING_APP_PATH := ${app_provider_path}/security/mobile_thinking
NAVYA_APP_PATH := ${app_provider_path}/shuttle/navya

# Outdated packages (depends on PADAM_REPORTS_DIR)
OUTDATED_AUDIT_INSTALL := pip install pip-audit >/dev/null 2>&1 || true
OUTDATED_AUDIT_CMD := ${OUTDATED_AUDIT_INSTALL} && pip-audit --format=json | python -m json.tool
OUTDATED_CMD := pip list --outdated --format=columns | grep -v "^Package" | grep -v "^-------" || echo "No outdated packages"
OUTDATED_JSON_CMD := pip list --outdated --format=json
OUTDATED_REPORTS_DIR := ${PADAM_REPORTS_DIR}/pip-outdated

# Padam app subdirectories (depends on PADAM_APP_DIR)
PADAM_APPS_DIR ?= ${PADAM_APP_DIR}/apps
PADAM_MEDIA_DIR ?= ${PADAM_APP_DIR}/media
PADAM_MIGRATIONS_DIR ?= ${PADAM_APP_DIR}/migrations
PADAM_STATIC_DIR ?= ${PADAM_APP_DIR}/static
PADAM_TEMPLATES_DIR ?= ${PADAM_APP_DIR}/templates
PADAM_TOOLS_DIR ?= ${PADAM_APP_DIR}/tools

# Padam image versions (read from images_versions.txt — updated automatically by bump-image-versions.yml)
PADAM_AV_IMAGE_BACKEND_VERSION = $(shell grep PADAM_AV_IMAGE_BACKEND_VERSION images_versions.txt | cut -d"=" -f2 | xargs)
PADAM_AV_IMAGE_PROTOBUF_VERSION = $(shell grep PADAM_AV_IMAGE_PROTOBUF_VERSION images_versions.txt | cut -d"=" -f2 | xargs)

# Application version (read from setup.cfg — updated automatically by bump-image-versions.yml and release-on-master.yml)
PADAM_AV_APP_VERSION = $(shell grep '^version' padam_av/setup.cfg | cut -d'=' -f2 | xargs)

# Palomata app path (depends on app_provider_path)
PALOMATA_APP_PATH := ${app_provider_path}/shuttle/palomata

# Project folders
project_required_files_and_folder = padam_av/statics/
quality_required_files_and_folder = reports/
tests_required_files_and_folder = reports/tests/html

# ============================================================================
# DOCKER IMAGES & SERVICES (depend on docker_repo, versions, GIT_BRANCH)
# ============================================================================

# Backend image (shared version for dev/docs/production/quality/tests — depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__backend_image=${docker_repo}/production:${PADAM_AV_IMAGE_BACKEND_VERSION}
PADAM_AV_BACKEND_IMAGE=${__backend_image}

# Dev image & service (depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__dev_image=${docker_repo}/dev:${PADAM_AV_IMAGE_BACKEND_VERSION}
__dev_service_name:=back-dev

# Docs image & service (depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__docs_image=${docker_repo}/docs:${PADAM_AV_IMAGE_BACKEND_VERSION}
__docs_service_name:=docs

# Production images & service (depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__prod_image=${docker_repo}/production:${PADAM_AV_IMAGE_BACKEND_VERSION}
__prod_service_name:=back
__production_image=${docker_repo}/production:${PADAM_AV_IMAGE_BACKEND_VERSION}

# Protobuf image (depends on docker_repo, PADAM_AV_IMAGE_PROTOBUF_VERSION, GIT_BRANCH)
__protobuf_image=${docker_repo}/protobuf:${PADAM_AV_IMAGE_PROTOBUF_VERSION}

# Quality image & service (depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__quality_image=${docker_repo}/quality:${PADAM_AV_IMAGE_BACKEND_VERSION}
__quality_service_name:=quality

# Tests image & service (depends on docker_repo, PADAM_AV_IMAGE_BACKEND_VERSION, GIT_BRANCH)
__tests_image=${docker_repo}/tests:${PADAM_AV_IMAGE_BACKEND_VERSION}
__tests_service_name:=tests

# All services (depends on all service names)
SERVICES := ${__dev_service_name} ${PROTOBUF_SERVICE_NAME}

# ============================================================================
# DOCKER RUN COMMANDS (depend on docker compose, services, volumes)
# ============================================================================

# Manage.py commands (depends on __docker_compose_project_base_command, DOCKER_RUN_*, __dev_service_name)
__manage_py_run:=${__docker_compose_project_base_command} run --interactive --tty ${DOCKER_RUN_ARGS} ${DOCKER_RUN_ENV} ${__dev_service_name} python manage.py
__manage_py_run_no_deps:=${__docker_compose_project_base_command} run --interactive --tty ${DOCKER_RUN_ARGS} --no-deps ${DOCKER_RUN_ENV} ${__dev_service_name} python manage.py

# General run commands (depends on __docker_compose_project_base_command, DOCKER_RUN_*)
__run_cmd:=${__docker_compose_project_base_command} run --interactive --tty ${DOCKER_RUN_ARGS} -v ${PWD}/docs:/docs -v ${PWD}/reports:/reports -v ${PWD}/docker/scripts:/scripts ${DOCKER_RUN_WORK_DIR} ${DOCKER_RUN_ENV}
__run_cmd_no_deps:=${__docker_compose_project_base_command} run --interactive --tty ${DOCKER_RUN_ARGS} --no-deps -v ${PWD}/.github:/github -v ${PWD}/docs:/docs -v ${PWD}/reports:/reports -v ${PWD}/docker/scripts:/scripts ${DOCKER_RUN_WORK_DIR} ${DOCKER_RUN_ENV}

# Quality run command (depends on __docker_compose_project_base_command, DOCKER_RUN_*, __quality_service_name)
__run_quality_cmd:=${__docker_compose_project_base_command} run ${DOCKER_RUN_ARGS} --no-deps -v ${PWD}/reports:/reports -v ${PWD}/.config:/.config --workdir=/code ${__quality_service_name}

# Docs run command (depends on __docker_compose_project_base_command, DOCKER_RUN_*, __docs_service_name)
__run_docs_cmd:=${__docker_compose_project_base_command} run ${DOCKER_RUN_ARGS} --no-deps -v ${PWD}/docs:/docs -v ${PWD}/docker/scripts:/scripts --workdir=/code ${__docs_service_name}

# Test run command (depends on __docker_compose_project_base_command, DOCKER_RUN_*, DATABASE_*, __dev_service_name)
__run_test_cmd:=${__docker_compose_project_base_command} --profile dev run --no-deps ${DOCKER_RUN_ARGS} -v ${PWD}/reports:/reports ${DOCKER_RUN_WORK_DIR} --env DJANGO_LOG_LEVEL=${DJANGO_LOG_LEVEL} --name AV-tests --entrypoint="python" --env DATABASE_HOST=${DATABASE_HOST} --env DATABASE_PASSWORD=${DATABASE_PASSWORD} --env DATABASE_PORT=${DATABASE_PORT} --env DATABASE_USERNAME=${DATABASE_USERNAME} ${__dev_service_name} manage.py test --settings=settings.tests --coverage-xml --verbosity ${DJANGO_VERBOSITY}

# ============================================================================
# EXPORTS
# ============================================================================

export DATABASE_NAME
