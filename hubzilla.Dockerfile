FROM php:8.1-fpm-alpine

COPY --chmod=766 volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt

RUN \
  cat /usr/local/share/ca-certificates/root_ca.crt >> /etc/ssl/certs/ca-certificates.crt && \
  cat /usr/local/share/ca-certificates/root_ca.crt >> /etc/ssl1.1/certs/ca-certificates.crt

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install required dependencies and php extensions
ADD --chmod=755 \
  https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
  /usr/local/bin/
RUN \
  apk add --no-cache bash && \
  install-php-extensions gd pdo_pgsql zip


USER www-data
WORKDIR /var/www/html

# Install and set up Hubzilla and default addons
#
# Also make sure we add the step CA cert to the internal cert store used by
# Hubzilla.
ARG HUBZILLA_VERSION=8.8.3
ADD --chown=www-data https://framagit.org/hubzilla/core/-/archive/${HUBZILLA_VERSION}/core-${HUBZILLA_VERSION}.tar.gz hubzilla.tar.gz
RUN \
  tar -xzf hubzilla.tar.gz --strip-components=1\
  && ./util/add_addon_repo "https://framagit.org/hubzilla/addons.git" hzaddons \
  $$ mkdir -p "store/[data]/smarty3" \
  $$ cat /usr/local/share/ca-certificates/root_ca.crt >> ./library/cacert.pem

USER root

# Set up periodic cron job to handle background tasks
COPY volumes/hubzilla/crontab /etc/periodic/15min/hubzilla.sh
