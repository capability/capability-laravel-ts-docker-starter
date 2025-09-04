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
