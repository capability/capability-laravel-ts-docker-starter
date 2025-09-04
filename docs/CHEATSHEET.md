# Project Cheatsheet

> TL;DR for tools, commands, CI, Renovate, and “gotchas”. Copy/paste friendly.

## Layout

```
apps/
  backend/        # Laravel 12 app (PHP 8.3 base, 8.4 CI)
  frontend/       # Vite + TS skeleton (framework-agnostic)
.devcontainer/    # VS Code “Reopen in Container”
.github/          # CI + Renovate
infra/            # (otel, prometheus, mock, etc.)
docker-compose.yml
docker-compose.dev.yml
```

## Services & Ports

* **web (nginx)** → [http://localhost:\${WEB\_PORT:-8080}](http://localhost:${WEB_PORT:-8080})
* **api (php-fpm)** → internal :9000
* **db (mysql 8.4)** → localhost:\${DB\_PORT:-3307}
* **cache (redis 7)** → localhost:\${REDIS\_PORT:-6380}
* **mail (mailpit)** → UI [http://localhost:8025](http://localhost:8025), SMTP :1025
* **frontend (vite dev)** → [http://localhost:\${UI\_PORT:-5173}](http://localhost:${UI_PORT:-5173}) (profile `ui`)

## Tooling (pinned)

**Package managers**

* Node via asdf/Corepack; **pnpm 10.15.1** activated by Corepack
* Composer 2 (from image)

**Frontend (apps/frontend)**

* Vite `7.1.4`, TypeScript `5.9.2`, ESLint `9.34.0`, Vitest `3.2.4`, happy-dom `18.0.1`
* No UI framework enforced; `index.html` + `src/main.ts` only

**Backend (apps/backend)**

* Laravel `^12` (framework pinned after scaffold)
* Dev tools (exact pins recommended):

  * Pest `3.8.4` + pest-plugin-laravel `3.2.0` (PHPUnit 11 compatible)
  * Pint `1.24.0`
  * PHPStan `2.1.22` + Larastan `3.6.1`
  * Rector `2.1.4`
* Coverage: **pcov** (fast) baked into php image
* Debugger: **Xdebug** installed, **off by default** (toggle via `XDEBUG_MODE`)

## One-time onboarding

```bash
# Host
docker compose up -d db cache mail api web
# Or: just up

# Backend
just install
just migrate
# Smoke
just test
```

## Dev loops

* **Run tests (no coverage):** `just test`
* **Coverage (pcov in container):** `just test-cov`
* **Static analysis:** `just stan`
* **Format check / fix:** `just lint` / `just lint-fix`
* **Frontend dev server:** `just fe-install && just fe-dev`
* **Debug (Xdebug on/off):** `just xdebug-on` / `just xdebug-off`
* **Where am I? (host vs container):** `just whereami`

> All `just` recipes work from **host** or **VS Code devcontainer**. Paths auto-resolve to `/workspace/apps/backend` (devcontainer) or `/var/www/html` (service container).

## VS Code

* **Open in Container:** Command Palette → *Dev Containers: Reopen in Container*
* Extensions (inside container): PHP Intelephense, Docker, GitLens, etc.
* **Launch configs** (`.vscode/launch.json`):

  * *Frontend: Vite (5173)*
  * *Backend: PHP (Xdebug)* (`port 9003`, path mapping `/var/www/html` ↔ `apps/backend`)
* **Debugging**: run `just xdebug-on`, set breakpoints, start *Backend: PHP (Xdebug)*, hit route.

## CI (GitHub Actions)

* Workflow: `.github/workflows/ci.yml`

  * Triggers: PRs to default branch, manual `workflow_dispatch`
  * Jobs:

    * **frontend**: pnpm install, lint/typecheck, build, unit tests
    * **backend** (matrix PHP **8.3**, **8.4**): composer install, `composer lint`, `composer stan`, `composer test` (optionally `test-cov` with `pcov`)
  * Caching: pnpm store, Composer cache

> Add a status badge to `README.md` for visibility.

## Renovate

* Config: `.github/renovate.json` (preset `renovate/presets/small-auto.json`)
* Composer rules (suggested):

  * Pin (`rangeStrategy: "pin"`) for dev tools (Pest/Pint/PHPStan/Rector)
  * Auto-merge **minor/patch** for dev tools; majors manual
* Node/pnpm:

  * Pin FE toolchain (`"version": "x.y.z"`), let Renovate raise PRs
* Validate: `npx renovate-config-validator` (optional)

## Version/Update Policy

* **Package managers**: pin exactly; bump deliberately
* **FE tooling**: pinned; allow Renovate PRs weekly
* **BE tools**: pinned; allow patch/minor automerge for dev-only tools
* **PHP**: prod base 8.3, CI tests 8.3/8.4 → promote when green
* **Laravel**: track 12.x patch releases via Renovate PRs; no auto-merge

## Common gotchas & fixes

* **Pint writes to `/tmp` denied**: fixed by either:
  * `TMPDIR=storage/framework/cache` in `composer.json` scripts (already set), or
  * Compose `tmpfs: /tmp:rw,noexec,nosuid,nodev`.

### Useful commands (complete list)

**Utility**

* `just whereami` — print `host` or `inside-container`. *(Host/Container)*
* `just sh` — open a shell in `api` (host) / reuse current shell (container). *(Host/Container)*
* `just up` — start db, cache, mail, api, web. *(Host only)*
* `just down` — stop all, remove orphans. *(Host only)*
* `just logs` — tail api logs. *(Host only)*

**Backend (Laravel)**

* `just install` — `composer install`. *(Host/Container)*
* `just test` — run tests. *(Host/Container)*
* `just test-cov` — tests with coverage (falls back to `artisan test --coverage`). *(Host/Container)*
* `just lint` — Pint check. *(Host/Container)*
* `just lint-fix` — Pint fix. *(Host/Container)*
* `just stan` — PHPStan. *(Host/Container)*
* `just rector` — Rector. *(Host/Container)*
* `just migrate` — `php artisan migrate --force`. *(Host/Container)*
* `just artisan <args>` — pass-through to `artisan`. *(Host/Container)*

**Debug**

* `just xdebug-on` *(host only)* — restart `api` with `XDEBUG_MODE=debug,develop`.
* `just xdebug-off` *(host only)* — restart `api` with `XDEBUG_MODE=off`.

**Frontend (pnpm/Vite) — via `frontend` service**

* `just fe-install` — clean install (`rm -rf node_modules`, frozen). *(Host only)*
* `just fe-install-fast` — idempotent install (keeps `node_modules`). *(Host only)*
* `just fe-dev` — start Vite dev server & tail logs. *(Host only)*
* `just fe-down` — stop frontend service. *(Host only)*
* `just fe-shell` — interactive shell with pnpm prepped. *(Host only)*
* `just fe-proof-cache` — verify pnpm store & offline install. *(Host only)*

**pnpm store maintenance**

* `just fe-store-stat` — show store path & size. *(Host only)*
* `just fe-store-prune` — prune unreferenced pkgs. *(Host only)*
* `just fe-store-clear` — wipe `/pnpm-store` volume. *(Host only)*

**CI simulators (mirror `.github/workflows/ci.yml`)**

* `just ci` — backend (SQLite) + frontend. *(Host only)*
* `just ci-all` — backend (SQLite + MySQL) + frontend. *(Host only)*
* `just ci-backend-sqlite` — backend on SQLite (in-memory). *(Host/Container)*
* `just ci-backend-mysql` — backend on MySQL (brings `db` up). *(Host only)*
* `just ci-frontend` — FE lint/typecheck/test/build. *(Host only)*

## Health checks

* Nginx health: `docker compose logs web` (hits `/api/healthz` or `/api/health`)
* App key (once): `docker compose exec -T api php artisan key:generate`
