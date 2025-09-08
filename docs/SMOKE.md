# SMOKE: Minimal bring-up and checks

Goal: prove each tier starts and answers a very basic request. No DB migrations, no artisan, no jobs. Use Compose profiles to bring services up in small sets.

## Conventions

* Project root has `.env` and `docker-compose.yml`
* Profiles map to purpose folders under `infra/`

  * `ssl` → `infra/ssl/` (Caddy)
  * `mock` → `infra/mock/` (Prism)
  * `monitoring` → `infra/monitoring/` (Prometheus, Grafana)
  * `logging` → `infra/logging/` (Loki) \[only if you have it configured]
  * `tracing` → `infra/tracing/` (OTEL Collector)
  * `ui` → Vite dev server
* Use `curl -i` to see HTTP status codes

---

## 0. Clean slate

```bash
# remove only this project's containers, volumes, networks
docker compose -p ${PROJECT_SLUG} down -v --remove-orphans || true

# double check nothing left from this project
docker ps --filter name=${PROJECT_SLUG}_
docker network rm ${PROJECT_SLUG}_default || true
```

---

## Tier 0. Core services

Bring up only web, api, db, cache, mail.

```bash
docker compose up -d web api db cache mail
docker compose ps
```

Smoke checks:

```bash
# web responds
curl -i http://localhost:8080/api/healthz

# redis alive
docker compose exec cache redis-cli PING

# mailpit UI reachable
curl -i http://localhost:8025/
```

Tear down if you want to proceed cleanly to other tiers:

```bash
docker compose down
```

---

## UI. Frontend dev server

```bash
COMPOSE_PROFILES="ui" docker compose up -d
docker compose ps
curl -i http://localhost:5173/
```

---

## Tier 1. Horizon

```bash
docker compose up -d horizon
docker ps --filter name=horizon
# simple exec to prove the container is alive
docker compose exec horizon sh -c 'echo ok'
# optional logs peek
docker compose logs --tail=50 horizon
```

---

## Tier 2. Monitoring

### Prometheus

Prereq: minimal config at `infra/monitoring/prometheus/prometheus.yml` with only self-scrape

```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs: [{ targets: ["localhost:9090"] }]
```

Bring up and check:

```bash
COMPOSE_PROFILES="monitoring" docker compose up -d prometheus
curl -sf http://localhost:9090/-/healthy && echo "prometheus OK"
curl -i http://localhost:9090/graph
```

### Grafana

```bash
COMPOSE_PROFILES="monitoring" docker compose up -d grafana
curl -i http://localhost:3000/login
```

You can log in via browser later and add Prometheus as a datasource at `http://prometheus:9090`.

---

## Logging. Loki

If you have Loki configured and exposed on 3100:

```bash
COMPOSE_PROFILES="logging" docker compose up -d loki
curl -i http://localhost:3100/ready
```

If you have not wired any log shippers yet, this still proves the service is up.

---

## Tracing. OpenTelemetry Collector

Minimal config at `infra/tracing/otel/config.yaml` with health and OTLP listeners:

```yaml
extensions:
  health_check: { endpoint: 0.0.0.0:13133 }
receivers:
  otlp:
    protocols:
      http: { endpoint: 0.0.0.0:4318 }
      grpc: { endpoint: 0.0.0.0:4317 }
exporters:
  debug: { verbosity: basic }
service:
  extensions: [health_check]
  pipelines:
    traces:  { receivers: [otlp], exporters: [debug] }
    metrics: { receivers: [otlp], exporters: [debug] }
    logs:    { receivers: [otlp], exporters: [debug] }
```

Bring up and check:

```bash
COMPOSE_PROFILES="tracing" docker compose up -d otel-collector
curl -i http://localhost:13133/
curl -i http://localhost:4318/
# optional grpc socket check
nc -zv localhost 4317
```

---

## Mock. Prism

`infra/mock/openapi.yaml` should at least include:

```yaml
openapi: 3.0.3
info: { title: Mock API, version: 0.0.1 }
paths:
  /health:
    get:
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema: { type: object, properties: { ok: { type: boolean } }, required: [ok] }
              examples: { default: { value: { ok: true } } }
```

Bring up and check:

```bash
COMPOSE_PROFILES="mock" docker compose up -d prism
curl -i http://localhost:4010/health
```

---

## SSL. Caddy

Prereq: `infra/ssl/Caddyfile` and local mkcert files in `infra/ssl/certs/`

Bring up and check:

```bash
COMPOSE_PROFILES="ssl" docker compose up -d caddy
# confirm HTTPS responds with local override
curl -I https://${DOMAIN} --resolve ${DOMAIN}:443:127.0.0.1 -k
```

---

## All-in quick smokes

```bash
# start selected tiers
COMPOSE_PROFILES="ui monitoring logging tracing mock ssl" docker compose up -d \
  prometheus grafana loki otel-collector prism caddy

# checks
curl -sf http://localhost:9090/-/healthy && echo "prometheus OK"
curl -i  http://localhost:3000/login
curl -i  http://localhost:3100/ready
curl -i  http://localhost:13133/
curl -i  http://localhost:4318/
curl -i  http://localhost:4010/health
curl -I  https://${DOMAIN} --resolve ${DOMAIN}:443:127.0.0.1 -k
```

---

## Tear down

```bash
# only services started with current profiles
docker compose down

# ensure nothing remains for this project
docker compose -p ${PROJECT_SLUG} down -v --remove-orphans || true
docker rm -f $(docker ps -aq -f name=${PROJECT_SLUG}_) 2>/dev/null || true
docker network rm ${PROJECT_SLUG}_default 2>/dev/null || true
```

---

## Troubleshooting quick refs

* Port shows closed on host

  * Confirm service `ports:` map in compose
  * `docker compose port <service> <container-port>`
* No output with `curl -sf`

  * That can be success. Add `-i` to see `HTTP/200` headers
* Compose says network in use after down

  * `docker ps --filter network=${PROJECT_SLUG}_default`
  * Stop or `docker rm -f` any remaining containers
* Prometheus scraping your web container

  * Remove that job unless you have a `/metrics` endpoint
* Horizon minimal check

  * `docker compose exec horizon sh -c 'echo ok'` and tail logs

---
