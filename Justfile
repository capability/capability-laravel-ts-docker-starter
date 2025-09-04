# ============================================================================
# Justfile — host/container aware helpers for Laravel backend + pnpm frontend
# ============================================================================
set shell := ["bash", "-euo", "pipefail", "-c"]

# Detect if we're inside a container (devcontainer or service)
_in_container := `test -f /.dockerenv && echo 1 || echo 0`

# Docker Compose + services
compose   := "docker compose"
api_svc   := "api"
fe_svc    := "frontend"

# Backend working dir (devcontainer: /workspace/apps/backend, service: /var/www/html)
backend_cd := 'B=/workspace/apps/backend; [ -d "$B" ] || B=/var/www/html; cd "$B"'

# Frontend working dir (inside the frontend container)
fe_dir := "/usr/src/app"

# Guard: some recipes must run on the host (api devcontainer typically lacks Docker CLI)
ensure_host := '''
if [ "{{_in_container}}" = "1" ]; then
  echo "Run this from the host (not inside the container/devcontainer)."; exit 1;
fi
'''

# ----------------------------------------------------------------------------
# Utility
# ----------------------------------------------------------------------------
whereami:
    @if [ "{{_in_container}}" = "1" ]; then echo "inside-container"; else echo "host"; fi

sh:
    @if [ "{{_in_container}}" = "1" ]; then \
      exec bash; \
    else \
      {{compose}} exec -it -u app {{api_svc}} bash; \
    fi

up:
    @{{ensure_host}}
    {{compose}} up -d db cache mail {{api_svc}} web
    {{compose}} ps

down:
    @{{ensure_host}}
    {{compose}} down --remove-orphans

nuke:
    @{{ensure_host}}
    {{compose}} down -v --remove-orphans

restart:
    @{{ensure_host}}
    {{compose}} up -d --force-recreate

logs svc='':
    @{{ensure_host}}
    {{compose}} logs -f --tail=200 {{api_svc}}

# ----------------------------------------------------------------------------
# Backend (Laravel)
# ----------------------------------------------------------------------------
install:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer install --no-interaction; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer install --no-interaction'; \
    fi

test:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer test; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer test'; \
    fi

test-cov:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && (composer run -q test:cov || php artisan test --coverage --min=0); \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && (composer run -q test:cov || php artisan test --coverage --min=0)'; \
    fi

lint:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer lint; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer lint'; \
    fi

lint-fix:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer lint:fix; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer lint:fix'; \
    fi

stan:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer stan; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer stan'; \
    fi

rector:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && composer rector; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && composer rector'; \
    fi

migrate:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && php artisan migrate --force; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && php artisan migrate --force'; \
    fi

artisan +ARGS:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}} && php artisan {{ARGS}}; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc '{{backend_cd}} && php artisan {{ARGS}}'; \
    fi

# ----------------------------------------------------------------------------
# Frontend (pnpm/Vite) — always via the `frontend` service
# Requires: apps/frontend/.npmrc with `store-dir=/pnpm-store` and a volume mount
# ----------------------------------------------------------------------------

# Install deps in a clean, deterministic way (CI-like)
fe-install:
    @{{ensure_host}}
    {{compose}} pull {{fe_svc}} >/dev/null || true
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} -e CI=1 {{fe_svc}} sh -lc '\
      corepack enable && \
      corepack prepare pnpm@10.15.1 --activate && \
      rm -rf node_modules && \
      pnpm install --frozen-lockfile --reporter=silent --no-color \
    '

# Fast local install (keeps node_modules)
fe-install-fast:
    @{{ensure_host}}
    {{compose}} pull {{fe_svc}} >/dev/null || true
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} -e CI=1 {{fe_svc}} sh -lc '\
      corepack enable && \
      corepack prepare pnpm@10.15.1 --activate && \
      pnpm install --frozen-lockfile --reporter=silent --no-color \
    '

# Long-running dev server
fe-dev:
    @{{ensure_host}}
    {{compose}} up -d --force-recreate --no-deps {{fe_svc}}
    {{compose}} logs -f --since=10s {{fe_svc}}

# Stop only the FE service
fe-down:
    @{{ensure_host}}
    {{compose}} stop {{fe_svc}}

# Interactive shell with pnpm prepped
fe-shell:
    @{{ensure_host}}
    {{compose}} run --rm -it --no-deps -w {{fe_dir}} {{fe_svc}} sh -lc '\
      corepack enable && corepack prepare pnpm@10.15.1 --activate && exec sh'

# Prove cache & offline install
fe-proof-cache:
    @{{ensure_host}}
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} -e CI=1 {{fe_svc}} sh -lc '\
      set -e; corepack enable; corepack prepare pnpm@10.15.1 --activate; \
      echo cfg=$(pnpm config get store-dir); \
      echo path=$(pnpm store path); \
      du -sh /pnpm-store || true; \
      rm -rf node_modules; \
      pnpm install --frozen-lockfile --offline --reporter=silent --no-color; \
      echo OFFLINE_OK \
    '

# ---------- pnpm store maintenance -------------------------------------------

fe-store-stat:
    @{{ensure_host}}
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} {{fe_svc}} sh -lc '\
      corepack enable && corepack prepare pnpm@10.15.1 --activate && \
      echo path=$(pnpm store path) && du -sh /pnpm-store || true'

fe-store-prune:
    @{{ensure_host}}
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} {{fe_svc}} sh -lc '\
      corepack enable && corepack prepare pnpm@10.15.1 --activate && \
      pnpm store prune'

fe-store-clear:
    @{{ensure_host}}
    {{compose}} run -T --rm --no-deps {{fe_svc}} sh -lc 'rm -rf /pnpm-store/* && echo "pnpm store cleared"'

# ----------------------------------------------------------------------------
# CI simulators (mirror .github/workflows/ci.yml)
# ----------------------------------------------------------------------------
ci:
    just ci-backend-sqlite
    just ci-frontend

ci-all:
    just ci-backend-sqlite
    just ci-backend-mysql
    just ci-frontend

ci-backend-sqlite:
    @if [ "{{_in_container}}" = "1" ]; then \
      {{backend_cd}}; \
      composer install --no-interaction --no-progress --prefer-dist; \
      php -r "file_exists('.env') || copy('.env.example','.env');"; \
      php artisan key:generate --force; \
      php artisan config:cache; \
      php artisan route:cache; \
      php artisan test --coverage-clover=coverage.xml; \
    else \
      {{compose}} exec -T -u app {{api_svc}} bash -lc ' \
        {{backend_cd}}; \
        composer install --no-interaction --no-progress --prefer-dist; \
        php -r "file_exists('\''.env'\'') || copy('\''.env.example'\'','\''.env'\'');"; \
        php artisan key:generate --force; \
        php artisan config:cache; \
        php artisan route:cache; \
        php artisan test --coverage-clover=coverage.xml \
      '; \
    fi

ci-backend-mysql:
    @{{ensure_host}}
    {{compose}} up -d db >/dev/null
    {{compose}} exec -T -u app {{api_svc}} bash -lc ' \
      {{backend_cd}}; \
      composer install --no-interaction --no-progress --prefer-dist; \
      php -r "file_exists('\''.env'\'') || copy('\''.env.example'\'','\''.env'\'');"; \
      php artisan key:generate --force; \
      php artisan config:cache; \
      php artisan route:cache; \
      DB_CONNECTION=mysql DB_HOST=db DB_PORT=3306 DB_DATABASE=laravel DB_USERNAME=laravel DB_PASSWORD=secret \
      php artisan test --coverage-clover=coverage.xml \
    '

ci-frontend:
    @{{ensure_host}}
    {{compose}} pull {{fe_svc}} >/dev/null || true
    {{compose}} run -T --rm --no-deps -w {{fe_dir}} -e CI=1 {{fe_svc}} sh -lc '\
      set -e; \
      corepack enable; \
      corepack prepare pnpm@10.15.1 --activate; \
      rm -rf node_modules; \
      pnpm install --frozen-lockfile --reporter=silent --no-color; \
      echo "[lint]"; pnpm lint; \
      echo "[typecheck]"; pnpm typecheck; \
      echo "[test]"; pnpm test -- --coverage; \
      echo "[build]"; pnpm build \
    '

# Debug toggles (host only) ----------------------------------------------------
xdebug-on:
    @if [ "{{_in_container}}" = "1" ]; then \
      echo "Run this from the host"; exit 1; \
    else \
      XDEBUG_MODE=debug,develop {{compose}} up -d --force-recreate {{api_svc}}; \
      {{compose}} logs -f --since=10s {{api_svc}} | sed -n '1,80p'; \
    fi

xdebug-off:
    @if [ "{{_in_container}}" = "1" ]; then \
      echo "Run this from the host"; exit 1; \
    else \
      XDEBUG_MODE=off {{compose}} up -d --force-recreate {{api_svc}}; \
      {{compose}} logs -f --since=10s {{api_svc}} | sed -n '1,80p'; \
    fi
