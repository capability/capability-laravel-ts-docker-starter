# Onboarding Guide

Welcome! This document helps you get from a fresh clone to a working dev environment.

---

## 1. Prerequisites

- **Docker Desktop** (or OrbStack / Colima) with Compose v2
- **mkcert** for local SSL  
  ```bash
  brew install mkcert nss
  mkcert -install
````

* **pnpm** via Corepack (ships with Node 16+):

  ```bash
  corepack enable
  ```

Optional but recommended:

* `just` for command shortcuts
* `git` and GitHub account

---

## 2. Clone and configure

```bash
git clone git@github.com:your-org/capability-laravel-ts-docker-starter.git
cd capability-laravel-ts-docker-starter
```

Copy env templates:

```bash
cp .env.example .env
cp apps/backend/.env.example apps/backend/.env
```

Edit `.env` and set:

```
COMPOSE_PROFILES=ssl,ui
DOMAIN=${DOMAIN}
```

Add to `/etc/hosts`:

```
127.0.0.1 ${DOMAIN}
```

Generate dev certs:

```bash
mkdir -p infra/caddy/certs
mkcert -cert-file infra/caddy/certs/${DOMAIN}.pem \
       -key-file infra/caddy/certs/${DOMAIN}-key.pem ${DOMAIN}
```

---

## 3. Bring up the stack

```bash
just up
```

This starts:

* PHP/Laravel API
* nginx
* Caddy (SSL)
* MySQL
* Redis
* Mailpit
* Vite frontend (if `ui` profile enabled)

Check:

```bash
curl -i https://${DOMAIN}/api/healthz
```

---

## 4. Backend (Laravel)

Generate key:

```bash
docker compose exec api php artisan key:generate
```

Run migrations:

```bash
docker compose exec api php artisan migrate
```

Run tests:

```bash
docker compose exec api ./vendor/bin/pest
```

---

## 5. Frontend (Vite + TS)

Install deps:

```bash
pnpm -C apps/frontend install
```

Start dev server:

```bash
pnpm -C apps/frontend dev
```

Access: [http://localhost:5173](http://localhost:5173)

---

## 6. Common commands

```bash
just up         # docker compose up -d
just down       # docker compose down
just nuke       # docker compose down -v
docker compose logs -f api
```

---

## 7. Profiles

* `ssl` → Caddy TLS termination
* `ui` → Vite frontend
* `monitoring` → Prometheus + Grafana
* `logging` → Loki
* `tracing` → OTel collector
* `mock` → Prism mock server

Enable via `.env`:

```
COMPOSE_PROFILES=ssl,ui,monitoring
```

---

You’re now ready to develop! See [`docs/CHEATSHEET.md`](docs/CHEATSHEET.md) for daily command references.
