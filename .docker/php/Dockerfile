# Configurable packages
ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=""

FROM php:${PHP_VERSION}-apache

ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN apt -y update && apt -y upgrade

RUN apt -y install \
    acl \
    bash \
    ca-certificates \
    git \
    openssh-client \
    rsync \
    patch \
    mariadb-client

RUN install-php-extensions json pdo_mysql curl gd imap xml opcache soap xml zip ssh2 mbstring ldap yaml snmp pcov

# Configurable php configuration
ENV MEMORY_LIMIT "256M"

COPY ./php.ini $PHP_INI_DIR/conf.d/

WORKDIR /srv
