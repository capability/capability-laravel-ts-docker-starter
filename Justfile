# ============================================================================
# Justfile — host/container aware helpers for Laravel backend + pnpm frontend
# ============================================================================
set shell := ["bash", "-euo", "pipefail", "-c"]

set dotenv-load
PROJECT_SLUG := env_var("PROJECT_SLUG")
DOMAIN := env_var("DOMAIN")

# Detect if we are inside a container (devcontainer or service)
_in_container := `test -f /.dockerenv && echo 1 || echo 0`

# Docker Compose + common service names
compose     := "docker compose"
api_svc     := "api"
web_svc     := "web"
db_svc      := "db"
cache_svc   := "cache"
mail_svc    := "mail"
fe_svc      := "frontend"
horizon_svc := "horizon"
caddy_svc   := "caddy"
prom_svc    := "prometheus"
graf_svc    := "grafana"
loki_svc    := "loki"
otel_svc    := "otel-collector"
prism_svc   := "prism"

# Backend working dir (devcontainer: /workspaces/*/apps/backend, service: /var/www/html)
backend_cd := 'B=/var/www/html; for p in /workspaces/*/apps/backend; do [ -d "$p" ] && B="$p" && break; done; cd "$B"'

# Frontend working dir inside the frontend container
fe_dir := "/usr/src/app"

# Guard: some recipes must run on the host
ensure_host := '''
if ! command -v docker >/dev/null 2>&1; then
  if [ -f /.dockerenv ] || [ -d /workspaces ]; then
    echo "You're inside a dev/service container. Run this on the host.";
  else
    echo "Docker CLI not found on PATH.";
  fi
  exit 1
fi
'''

default:
    @echo "Common recipes:"
    @echo "  up, down, nuke, quick-up-backend-ssl, quick-down-all, tiers-up, tiers-down"
    @echo "  install, test, fe-install, fe-dev, vs-code-be, vs-code-fe, vs-code-both"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
# Wait for services with healthchecks to become healthy
_wait_healthy services='db cache api web caddy':
    @set -e; \
    for s in {{services}}; do \
      id="$({{compose}} ps -q $$s)"; \
      [ -n "$$id" ] || continue; \
      echo "waiting: $$s"; \
      # if no healthcheck, skip
      if ! docker inspect -f '{{"{{"}}.State.Health{{"}}"}}' "$$id" 2>/dev/null | grep -q .; then \
        echo "no healthcheck for $$s, skipping"; \
        continue; \
      fi; \
      until [ "$$(docker inspect -f '{{"{{"}}.State.Health.Status{{"}}"}}' $$id)" = "healthy" ]; do \
        sleep 1; \
      done; \
    done; \
    echo "all healthy (where defined)"

# ----------------------------------------------------------------------------
# Quick starts
# ----------------------------------------------------------------------------
quick-up-backend-ssl:
    @{{ensure_host}}
    {{compose}} --profile ssl up -d {{db_svc}} {{cache_svc}} {{mail_svc}} {{api_svc}} {{web_svc}} {{caddy_svc}}
    just _wait_healthy
    {{compose}} ps
    echo "Backend + SSL up. Try: curl -I https://{{DOMAIN}} --resolve {{DOMAIN}}:443:127.0.0.1 -k"

quick-up-frontend-ssl:
    @{{ensure_host}}
    {{compose}} --profile ssl up -d {{fe_svc}} {{caddy_svc}}
    just _wait_healthy services='caddy'
    {{compose}} ps {{fe_svc}} {{caddy_svc}}
    echo "Frontend + SSL up. If Caddy proxies FE, hit your HTTPS domain. Otherwise: curl -i http://localhost:5173

