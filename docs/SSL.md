# SSL

This starter supports HTTPS out of the box using [Caddy](https://caddyserver.com/).  
Caddy can terminate TLS for both **development** (self-signed via mkcert) and **production** (automatic Let’s Encrypt).

---

## Development with mkcert

1. **Install mkcert**
   ```bash
   brew install mkcert nss
   mkcert -install
````

2. **Generate local certificates**

   ```bash
   mkdir -p infra/caddy/certs
   mkcert -cert-file infra/caddy/certs/app-skeleton.test.pem \
          -key-file  infra/caddy/certs/app-skeleton.test-key.pem app-skeleton.test
   ```

3. **Update hosts file**

   ```bash
   echo "127.0.0.1 app-skeleton.test" | sudo tee -a /etc/hosts
   ```

4. **Set environment**
   Root `.env`:

   ```dotenv
   COMPOSE_PROFILES=ssl
   DOMAIN=app-skeleton.test
   ```

   Backend `.env`:

   ```dotenv
   APP_URL=https://app-skeleton.test
   ```

5. **Bring up stack**

   ```bash
   docker compose up -d
   curl -i https://app-skeleton.test/api/healthz
   ```

You should see a `200 OK` and a JSON body.

---

## Production with Let’s Encrypt

1. Point DNS for your domain to the server running Docker.
   Example: `your.domain.com → <server IP>`

2. In root `.env`:

   ```dotenv
   COMPOSE_PROFILES=ssl
   DOMAIN=your.domain.com
   ```

   In `apps/backend/.env`:

   ```dotenv
   APP_URL=https://your.domain.com
   ```

3. Start the stack:

   ```bash
   docker compose up -d
   ```

Caddy will automatically request and renew certificates from Let’s Encrypt.

---

## Notes

* Dev certificates (`infra/caddy/certs/*.pem`) are ignored by git.
* Health checks and internal service communication remain plain HTTP on the Docker network.
* SSL termination happens at Caddy.
* For production, ensure port 80 and 443 are open to the internet.
