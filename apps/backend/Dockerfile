FROM php:8.3-fpm-bookworm AS base

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    git unzip zip \
    libicu-dev libzip-dev \
    libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev \
    gosu \
  ; rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" pdo_mysql intl zip gd \
 && pecl install redis \
 && docker-php-ext-enable redis

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Xdebug (debugging; coverage is off by default)
RUN set -eux; \
    pecl install xdebug; \
    docker-php-ext-enable xdebug
COPY docker/php/zz-xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini

# Install + enable pcov and write its ini
RUN set -eux; \
    pecl install pcov; \
    docker-php-ext-enable pcov; \
    { \
      echo "pcov.enabled=1"; \
      echo "pcov.directory=/var/www/html/app"; \
      echo 'pcov.exclude="~(vendor|storage|bootstrap/cache)~"'; \
    } > /usr/local/etc/php/conf.d/zz-pcov.ini

ARG UID=1000
ARG GID=1000
RUN set -eux; \
  if getent group "${GID}" >/dev/null; then GN="$(getent group "${GID}" | cut -d: -f1)"; else groupadd -g "${GID}" app; GN="app"; fi; \
  if ! id -u app >/dev/null 2>&1; then useradd -m -u "${UID}" -g "${GN}" app; fi

WORKDIR /var/www/html

COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php/zz-pool-user.conf /usr/local/etc/php-fpm.d/zz-pool-user.conf

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

FROM base AS development
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    curl jq rsync zsh zsh-autosuggestions zsh-syntax-highlighting bash-completion vim \
  ; rm -rf /var/lib/apt/lists/*
