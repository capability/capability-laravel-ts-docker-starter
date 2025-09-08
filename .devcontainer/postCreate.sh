#!/usr/bin/env bash
set -euo pipefail

# Start in the workspace root (repo root)
cd "${containerWorkspaceFolder:-/workspaces/${localWorkspaceFolderBasename:-workspace}}"

# Backend (Laravel)
if [ -f apps/backend/composer.json ]; then
  ( cd apps/backend && composer install )
  # optional: php artisan key:generate --force
fi

# Frontend (pnpm)
corepack enable
corepack prepare pnpm@10.15.1 --activate
if [ -f apps/frontend/pnpm-lock.yaml ]; then
  ( cd apps/frontend && pnpm install --frozen-lockfile )
fi

