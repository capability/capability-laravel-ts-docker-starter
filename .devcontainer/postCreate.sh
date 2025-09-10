#!/bin/sh
set -eu

cd /workspaces/app

# Backend deps
if [ -f apps/backend/composer.json ]; then
  ( cd apps/backend && composer install --no-interaction )
fi

echo "Post-create OK. Frontend deps start in the 'frontend' service."
