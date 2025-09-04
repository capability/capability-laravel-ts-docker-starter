# Contributing

Thanks for your interest in contributing! This repo is a Laravel + TypeScript + Docker starter. Contributions that improve developer experience, stability, or documentation are welcome.

## Development setup

```bash
# Backend env
cp apps/backend/.env.example apps/backend/.env

# Infra env
cp .env.example .env
# set COMPOSE_PROFILES as needed (e.g. ssl,ui,monitoring)

# Start stack
docker compose up -d

# Laravel key
docker compose exec api php artisan key:generate
````

Frontend setup:

```bash
corepack enable
pnpm -C apps/frontend install
pnpm -C apps/frontend dev
```

## Commit style

* Use **Conventional Commits** (`feat:`, `fix:`, `docs:`, `chore:` …).
* Keep lockfiles committed (`composer.lock`, `pnpm-lock.yaml`).
* Prefer squash merges into `main`.

## Prefered Conventional Commit Types (for this skeleton)

* **`feat:`** – new feature (backend, frontend, infra)
  *Example: `feat: add health check endpoint`*

* **`fix:`** – bug fix (logic, config, code)
  *Example: `fix: wrong Redis port in .env.example`*

* **`docs:`** – documentation only (README, guides, comments)
  *Example: `docs: correct onboarding link in README.md`*

* **`style:`** – formatting, whitespace, missing semicolons (no code change)
  *Example: `style: apply Pint auto-fixes`*

* **`refactor:`** – code change that neither fixes a bug nor adds a feature
  *Example: `refactor: extract common Docker healthcheck command`*

* **`perf:`** – performance improvement
  *Example: `perf: enable opcache in production Dockerfile`*

* **`test:`** – add or update tests
  *Example: `test: add Pest feature test for healthz endpoint`*

* **`build:`** – changes to build system, CI/CD, deps, or tooling
  *Example: `build: update phpstan to v2.0`*

* **`ci:`** – changes to CI config (GitHub Actions, workflows)
  *Example: `ci: fix full-ci APP_KEY quoting`*

* **`chore:`** – housekeeping (bump lockfile, ignore files, renames)
  *Example: `chore: remove stray .DS_Store`*

* **`revert:`** – revert a previous commit
  *Example: `revert: feat: add experimental tracing profile`*

## Quality gates

Run these before submitting a PR:

**Backend**

```bash
docker compose exec api ./vendor/bin/pint
docker compose exec api ./vendor/bin/phpstan
docker compose exec api ./vendor/bin/pest
```

**Frontend**

```bash
pnpm -C apps/frontend lint
pnpm -C apps/frontend test
```

## Issues and PRs

* Use issue templates where available.
* PRs should describe the change and link related issues.
* Bug reports should include repro steps.

## Security

Do **not** report vulnerabilities in public issues. See [SECURITY.md](SECURITY.md).
