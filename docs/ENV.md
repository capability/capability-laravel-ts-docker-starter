# Environment Variables

This starter uses two layers of environment files:

---

## Root `.env`

Controls **infrastructure** and Docker Compose settings.

Template: [`.env.example`](../.env.example)

Key variables:
- `COMPOSE_PROFILES` → which optional profiles to enable (`ssl`, `ui`, `monitoring`, …).  
- `DOMAIN` → hostname for SSL (e.g. `${DOMAIN}` or `your.domain.com`).  
- `WEB_PORT`, `DB_PORT_HOST`, `REDIS_PORT_HOST`, `UI_PORT` → host-exposed ports.  
- `MYSQL_*` → database user, password, and root password (container bootstrap).  
- `MAIL_FROM_*` → default sender identity for Mailpit in dev.

This file is **not committed**. Only the template is.

---

## Backend `apps/backend/.env`

Controls **Laravel application runtime**.

Template: [`apps/backend/.env.example`](../apps/backend/.env.example)

Key variables:
- `APP_NAME`, `APP_ENV`, `APP_KEY`, `APP_DEBUG`  
- `APP_URL` → must match your public URL (e.g. `https://${DOMAIN}`).  
- `LOG_CHANNEL`, `LOG_LEVEL`  
- `DB_*` → Laravel’s connection settings (map to the `db` service).  
- `REDIS_*` → Redis connection (map to the `cache` service).  
- `MAIL_*` → Mailer config (map to the `mail` service).  
- `AWS_*` → placeholders (standard Laravel pattern).  
- `VITE_APP_NAME` → frontend injection.

This file is **not committed**. Only the example template is.

---

## Frontend `apps/frontend/.env`

Optional — used by Vite if you need to inject custom variables.  
By default not provided. Example template: `apps/frontend/.env.example` if needed.  
Ignored by git.

---

## Git Ignore Rules

- `.env` and `.env.*` are ignored everywhere.  
- `*.env.example` is **kept** and committed (root and backend).  
- Dev certs (`infra/caddy/certs/*.pem`) are ignored.  

---

## Quick setup

```bash
cp .env.example .env
cp apps/backend/.env.example apps/backend/.env
# optional: cp apps/frontend/.env.example apps/frontend/.env
````
