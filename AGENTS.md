# AGENTS.md – Guidance for Coding Agents

This repo uses a simple tier model. Agents should target the **Tier 0 baseline** by default and guard anything higher behind profiles or env checks.

## Tiers and profiles

**Tier 0 (core, dev)** - always available locally  
- nginx + php-fpm + mysql + redis + mailpit  
- Health endpoints `/healthz` and `/readyz`  
- JSON logs to stderr (Monolog JsonFormatter)  
- Tests (Pest), linting (Pint), static analysis (PHPStan), refactoring (Rector)

**Tier 1 (delivery)**  
- Horizon, Sentry integration, smoke tests

**Tier 2 (monitoring, logging, tracing)**  
- Prometheus, Grafana, Loki, OTEL collector

**Tier 3 (scale)**  
- Octane, ProxySQL, k6

**Sidecar (mock)**  
- Prism mock server, OpenAPI specs

### Rules

- Do not assume Tier 1 to 3 are running. Generate code that works on Tier 0.  
- Use feature detection. Examples:
  - Enable Sentry only if `APP_ENV=production` and `SENTRY_DSN` is set.
  - Expose `/metrics` only if the metrics route exists or a flag is enabled.
  - For Octane, keep code stateless and framework-safe for long-lived workers.
- When adding tooling, place infra configs under `infra/<tool>/` and add a compose service with the right profile. Keep Tier 0 lightweight.

## Conventions

- DTOs are immutable with static factories (`fromArray`, `fromModel`).  
- Commands and Events: `VerbNounCommand` → `NounPastTenseEvent`.  
- Repositories return domain objects and hide Eloquent.  
- Logging is JSON only. No `var_dump` or `echo`.  
- Testing uses Pest for unit and feature. Playwright for smoke E2E.

## Example prompts you can fulfil

- “Add a new exporter for RabbitMQ metrics” → create `infra/rabbitmq_exporter/` and a compose service under the `monitoring` profile.  
- “Add a new DTO for bulk inventory upload” → put it in `app/Application/Inventory/DTOs/`, immutable, with `fromArray()`.  
- “Expose a counter on /metrics for stock adjustments” → update the metrics controller and register it behind a flag.

## Golden rules

- Do not break Tier 0. It must spin up fast.  
- Do not hard-require Tier 2 or 3 services. Guard them with profiles or env checks.  
- Keep Laravel `.env` separate from shell `.envrc`.  
- Update README.md whenever new infra or features are added.
