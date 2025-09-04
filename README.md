# capability-laravel-ts-docker-starter

Laravel API + Vite TS frontend on Docker (nginx, php-fpm, MySQL, Redis), with profiles for ssl, ui, monitoring, logging, tracing, mock.

This repository is intended as a **kick-start skeleton**: a clean, opinionated baseline for new projects.  
It provides Docker Compose services, sensible defaults for Laravel and Vite, example `.env` templates, and optional profiles for SSL, monitoring, logging, and more.  

⚠️  **Note:** This repo is not designed to be forked and turned into your application directly.  
You *can* fork it if you want to build a better skeleton or adapt it into your own starter, but for a new project you should clone/copy it as a starting point.

[![CI](https://github.com/capability/capability-laravel-ts-docker-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/your-handle/capability-laravel-ts-docker-starter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![Laravel](https://img.shields.io/badge/laravel-12-red.svg)](https://laravel.com/)
[![Node.js](https://img.shields.io/badge/node-22.x-6DA55F.svg)](https://nodejs.org/)
[![pnpm](https://img.shields.io/badge/pnpm-10.15.1-orange.svg)](https://pnpm.io/)
[![TypeScript](https://img.shields.io/badge/typescript-5.x-blue.svg)](https://www.typescriptlang.org/)

## Quickstart

```bash
# 1) Env templates
cp apps/backend/.env.example apps/backend/.env
cp .env.example .env

# 2) Enable SSL profile by default
# .env should include:
# COMPOSE_PROFILES=ssl
# DOMAIN=app-skeleton.test

# 3) Dev SSL with mkcert
brew install mkcert nss
mkcert -install
mkdir -p infra/caddy/certs
mkcert -cert-file infra/caddy/certs/app-skeleton.test.pem \
       -key-file  infra/caddy/certs/app-skeleton.test-key.pem app-skeleton.test
echo "127.0.0.1 app-skeleton.test" | sudo tee -a /etc/hosts

# 4) Up
docker compose up -d
````

URLs

* HTTPS via Caddy: [https://app-skeleton.test](https://app-skeleton.test)
* HTTP direct to nginx: [http://localhost:\${WEB\_PORT:-8080}](http://localhost:${WEB_PORT:-8080})

Profiles

* `ssl` Caddy on 80 and 443
* `ui` Vite dev server
* `monitoring` Prometheus and Grafana
* `logging` Loki
* `tracing` OpenTelemetry Collector
* `mock` Prism

Enable multiple

```bash
COMPOSE_PROFILES="ssl ui monitoring" docker compose up -d
```

Common commands

```bash
just up
just down
just nuke
docker compose logs -f caddy web api
```

## Envs

Root `.env` controls infra (ports, profiles, DOMAIN). Template: `.env.example`
Backend `.env` controls Laravel. Template: `apps/backend/.env.example`
Real `.env*` files are ignored.

## SSL

Dev: mkcert files live in `infra/caddy/certs/` and are ignored by git.
Prod: set `DOMAIN` to a real DNS name. Caddy will obtain and renew Let’s Encrypt certs.

See [`docs/SSL.md`](docs/SSL.md) for full steps.

## Tooling

* PHP 8.3, Laravel 11, Pest, PHPStan, Pint, Rector
* Node 22 + pnpm, Vite, Vitest
* Docker: nginx, php-fpm, mysql 8.4, redis 7, mailpit
* CI: GitHub Actions, Renovate

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Security policy in [`SECURITY.md`](SECURITY.md).

## License

See [`LICENSE`](LICENSE) (add your choice).

---

See also [`docs/CHEATSHEET.md`](docs/CHEATSHEET.md).
