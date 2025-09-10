# -----------------------------------------------------------------------------
# Base PHP-FPM image with extensions, tools, app-user, and FPM pool as app-user
# -----------------------------------------------------------------------------
FROM php:8.3-fpm-bookworm AS base

# System deps
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    curl git unzip zip \
    libicu-dev libzip-dev \
    libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev \
    gosu ca-certificates; \
  rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN set -eux; \
  docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
  docker-php-ext-install -j"$(nproc)" pdo_mysql intl zip gd; \
  pecl install redis; \
  docker-php-ext-enable redis

# Composer + just
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN curl -sSfL https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Xdebug (for local debug) and pcov (for fast coverage)
RUN set -eux; pecl install xdebug pcov; docker-php-ext-enable xdebug pcov
COPY docker/php/zz-xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini
# pcov defaults, tweak as you like
RUN set -eux; \
  { \
    echo "pcov.enabled=1"; \
    echo "pcov.directory=/var/www/html/app"; \
    echo 'pcov.exclude="~(vendor|storage|bootstrap/cache)~"'; \
  } > /usr/local/etc/php/conf.d/zz-pcov.ini

# Create unprivileged user/group with host-mapped UID/GID
ARG UID=1000
ARG GID=1000
RUN set -eux; \
  if getent group "${GID}" >/dev/null; then \
    GN="$(getent group "${GID}" | cut -d: -f1)"; \
  else \
    groupadd -g "${GID}" app-user; GN="app-user"; \
  fi; \
  id -u app-user >/dev/null 2>&1 || useradd -m -u "${UID}" -g "${GN}" -s /bin/bash app-user

# Composer defaults for app-user
ENV COMPOSER_HOME=/home/app-user/.composer \
    COMPOSER_CACHE_DIR=/home/app-user/.composer/cache \
    PATH="/home/app-user/.composer/vendor/bin:${PATH}"

# PHP config
WORKDIR /var/www/html
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Ensure FPM runs as app-user and listens on TCP (nginx talks to :9000)
# If you keep a custom pool file, it should contain: user=app-user, group=app-user, listen=0.0.0.0:9000
COPY docker/php/zz-pool-user.conf /usr/local/etc/php-fpm.d/zz-pool-user.conf

# Entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# Keep container default user as root so entrypoint can fix perms, FPM children drop to app-user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm","-F"]

# -----------------------------------------------------------------------------
# Development layer: extra shells/tools (only used when target=development)
# -----------------------------------------------------------------------------
FROM base AS development
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    curl jq rsync zsh zsh-autosuggestions zsh-syntax-highlighting \
    bash-completion vim; \
  rm -rf /var/lib/apt/lists/*

