# syntax=docker/dockerfile:experimental

FROM composer:2 AS COMPOSER
ENV COMPOSER_HOME=/usr/config/composer
ARG GITHUB_TOKEN
RUN if [ -z "$GITHUB_TOKEN" ]; then \
    echo "Warning: GITHUB_TOKEN is not set. This might cause issues with GitHub API rate limits." >&2; \
    composer config -g >&2; \
else \
    composer config -g github-oauth.github.com "$GITHUB_TOKEN"; \
fi
RUN composer global require laravel/installer


FROM php:8.4-fpm

ENV COMPOSER_HOME=/usr/config/composer
ARG USER_ID
ARG GROUP_ID
RUN usermod -u $USER_ID www-data && groupmod -g $GROUP_ID www-data

# Install php-src extensions
RUN apt-get -qq update && apt-get install -qq\
         libzip-dev \
         libpng-dev \
         libmagickwand-dev \
         unzip \
         mariadb-client \
         git
RUN  pecl install xdebug-3.4.7
RUN  pecl install excimer
RUN  docker-php-ext-enable xdebug
RUN  pecl install imagick
RUN  docker-php-ext-enable imagick
RUN  pecl install -o -f redis-6.2.0
RUN  docker-php-ext-enable redis
RUN  docker-php-ext-install \
         -j$(nproc) \
         zip \
         gd \
         bcmath \
         pcntl \
         pdo_mysql > /dev/null &&  \
     rm -rf /tmp/pear  > /dev/null && \
     rm -rf /var/lib/apt/lists/*
RUN mkdir /tmp/profile; chmod 777 /tmp/profile

# Install composer and dependencies
COPY --chown=www-data:www-data --from=COMPOSER /usr/bin/composer /usr/bin/composer
COPY --chown=www-data:www-data --from=COMPOSER /usr/config/composer /usr/config/composer

# Make sure composer can checkout github
RUN mkdir -p /var/www/.ssh/ && \
    touch /var/www/.ssh/known_hosts && \
    ssh-keyscan github.com >> /var/www/.ssh/known_hosts



WORKDIR /var/www/html

USER www-data
