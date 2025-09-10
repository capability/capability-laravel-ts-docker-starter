#!/usr/bin/env bash
set -euo pipefail

APP_USER=app-user
APP_GROUP=app-user
APP_HOME=/home/${APP_USER}
APP_ROOT=/var/www/html

mkdir -p \
  "${APP_ROOT}/vendor" \
  "${APP_ROOT}/storage/framework/cache" \
  "${APP_ROOT}/storage/framework/sessions" \
  "${APP_ROOT}/storage/framework/views" \
  "${APP_ROOT}/bootstrap/cache" \
  "${APP_HOME}/.composer" \
  "${APP_HOME}/.vscode-server" \
  /run/php

chown_if_needed() {
  local path="$1"
  if owner_uid=$(stat -c %u "$path" 2>/dev/null) && owner_gid=$(stat -c %g "$path" 2>/dev/null); then
    local target_uid target_gid
    target_uid=$(id -u "${APP_USER}")
    target_gid=$(getent group "${APP_GROUP}" | awk -F: '{print $3}')
    if [[ "${owner_uid}" != "${target_uid}" || "${owner_gid}" != "${target_gid}" ]]; then
      chown -R "${APP_USER}:${APP_GROUP}" "$path"
    fi
  else
    chown -R "${APP_USER}:${APP_GROUP}" "$path" || true
  fi
}

chown_if_needed "${APP_ROOT}/vendor"
chown_if_needed "${APP_ROOT}/storage"
chown_if_needed "${APP_ROOT}/bootstrap/cache"
chown_if_needed "${APP_HOME}/.composer"
chown_if_needed "${APP_HOME}/.vscode-server"

chmod -R u+rwX,g+rwX "${APP_HOME}/.vscode-server" || true

# Install composer deps if vendor missing and not production
if [[ ! -f "${APP_ROOT}/vendor/autoload.php" && "${APP_ENV:-local}" != "production" ]]; then
  su -s /bin/sh -c "cd '${APP_ROOT}' && composer install --prefer-dist --no-interaction" "${APP_USER}"
fi

# IMPORTANT: start php-fpm as root master (children drop to pool user)
exec php-fpm -F
