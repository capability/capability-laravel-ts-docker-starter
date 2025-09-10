# Dev Containers guide for this repo

This repo ships three Dev Container entry points, so VS Code can run the PHP backend and the Vite frontend with the right runtimes, extensions, and caches.

## Why we use Dev Containers here

- The IDE needs to index Composer packages and Node modules that live **inside containers**. Mounting the source only is not enough, the language servers must run where the tooling and PHP runtime exist.
- We persist the VS Code Server and language‑server caches on named volumes, indexing happens once, not on every rebuild.
- We align users and permissions, `app-user` in PHP containers and `node` in the frontend, so writes to the bind‑mounted workspace are safe and reproducible.

## Layout

- **Root multi‑service container**: `.devcontainer/devcontainer.json` uses `docker-compose.yml` to bring up api, web, db, cache, mail, and frontend. Workspace is the backend tree at `/var/www/html` by default, the repo root is also mounted at `/workspaces/<repo>` for convenience.
- **Backend only**: `apps/backend/.devcontainer/devcontainer.json` attaches straight to the `api` service with its own VS Code Server volume.
- **Frontend only**: `apps/frontend/.devcontainer/devcontainer.json` attaches to the `frontend` service, with a separate VS Code Server volume and PNPM store.

Small compose overrides in each folder set `init: true` the correct way for compose‑based devcontainers.

## Key config decisions

- **Users**: PHP runs FPM workers as `app-user`, the container still starts as root so the entrypoint can prepare and chown paths, then drops privileges for FPM. The frontend uses the image default `node` user.
- **VS Code Server cache**: mounted as a **named volume** at `~/.vscode-server` per window, eg `vscode-server-api` for backend and `vscode-server-frontend` for frontend. This keeps extensions and indexes between rebuilds.
- **Composer and PNPM caches**: mounted on named volumes to avoid cold installs.
- **No duplicate binds**: only compose owns `/var/www/html`. The devcontainer file does not bind to that path again, which avoids the “workspace does not exist” and race conditions.
- **No `runArgs` in compose variant**: for a tiny pid 1, use a compose snippet with `init: true` instead of `runArgs`.

## Typical workflows

### Open the whole stack at repo root
Use the root devcontainer, it opens the backend workspace at `/var/www/html` and also brings up the frontend service.

1. Open the repo folder in VS Code
2. “Reopen in Container”
3. You can edit backend under `/var/www/html`, frontend and infra are visible under `/workspaces/<repo>`

### Open backend only
Use the backend devcontainer in `apps/backend`.

- Open `apps/backend` in a new VS Code window, “Reopen in Container”
- The window attaches to the `api` service, Composer is available, PHP tooling runs in‑container

### Open frontend only
Use the frontend devcontainer in `apps/frontend`.

- Open `apps/frontend` in a new VS Code window, “Reopen in Container”
- The window attaches to the `frontend` service, Node 22 with Corepack is available, PNPM store is persisted

## CLI shortcuts

From the host, using your Justfile targets:

```sh
# Backend window
just vs-code-be

# Frontend window
just vs-code-fe

# Both windows
just vs-code-both
```

Under the hood, these run the Dev Containers CLI to warm up containers, then `code -n` to open windows.

## What to expect on first run

- VS Code Server installs under `~/.vscode-server` in each container, then your listed extensions install.
- Intelephense builds its index under `~/.vscode-server/data/User/globalStorage/bmewburn.vscode-intelephense-client`. This is on a named volume, so subsequent opens are fast.
- Frontend window prepares PNPM via Corepack and uses a persisted store, so `pnpm install` becomes incremental.

## Troubleshooting

- **Workspace does not exist**: remove any extra bind to `/var/www/html` in the devcontainer file. Let compose own that mount. The workspace should be `/var/www/html` or `/workspaces/<repo>`, not both to the same destination.
- **Stuck on postStart chown**: avoid `chown -R` on macOS bind mounts. Ownership is handled once in the entrypoint as root. Keep `postStartCommand` to `mkdir -p` only.
- **Permission denied writing VS Code Server**: ensure entrypoint creates and chowns `~/.vscode-server` for the session user, or set `containerUser: root` for setup and keep `remoteUser: app-user`.
- **Extensions re‑install every time**: verify the mount is a **volume**, not a bind. On the host, `docker inspect <api-container> | jq '.Mounts[] | select(.Destination==\"/home/app-user/.vscode-server\")'` should show `"Type": "volume"`.
- **Frontend service not starting in root window**: it is behind a compose profile by default, the root devcontainer includes a small override to enable it, or add `profiles: []` in an extra compose file referenced by the devcontainer.

## Notes on settings

- Avoid putting workspace settings that fight across windows at the user scope in the remote, prefer `.vscode/settings.json` in `apps/backend` or `apps/frontend` if you want window‑specific behaviour.
- To verify caches quickly in a container:
  ```sh
  du -sh ~/.vscode-server/data/User/globalStorage/bmewburn.vscode-intelephense-client 2>/dev/null || echo "no PHP index yet"
  du -sh ~/.vscode-server/extensions 2>/dev/null || true
  ```

That is all you need to run backend and frontend productively with consistent tooling and minimal re‑indexing.
