
FROM php:8.1-cli-alpine

RUN apk upgrade --update \
    && apk add --no-cache --virtual .build-deps nghttp2-dev \
    openssl \
    wget \
    libzip \
    zlib \
    imagemagick \
    linux-headers \
    autoconf \
    gcc \
    libc-dev \
    zip \
    unzip \
    make \
    g++ \
    curl \
    c-ares-dev \
    openssl-dev \
    curl-dev
RUN docker-php-ext-install pdo pdo_mysql
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install sockets
RUN docker-php-ext-install pcntl
RUN pecl channel-update pecl.php.net
RUN pecl install swoole && docker-php-ext-enable swoole
RUN pecl install apcu && docker-php-ext-enable apcu
RUN pecl install igbinary && docker-php-ext-enable igbinary
RUN pecl install mongodb && docker-php-ext-enable mongodb


RUN mkdir -p /app
COPY . /app

RUN sh -c "wget http://getcomposer.org/composer.phar && chmod a+x composer.phar && mv composer.phar /usr/local/bin/composer"
RUN cd /app && \
    /usr/local/bin/composer install --no-dev

# cleaning
RUN apk del .build-deps \
    && rm -rf /var/cache/apk/*
RUN docker-php-source delete

# RUN chown -R www-data: /app
RUN chmod -R 777 /app/storage

# Allow the user to specify Swoole options via ENV variables.
ENV SWOOLE_MAX_REQUESTS "500"
ENV SWOOLE_TASK_WORKERS "auto"
ENV SWOOLE_WATCH $false
ENV SWOOLE_WORKERS "auto"

# Expose the ports that Octane is using.
EXPOSE 8000

WORKDIR /app
# Run Swoole
CMD php artisan octane:start --server="swoole" --host="0.0.0.0" --workers=${SWOOLE_WORKERS} --task-workers=${SWOOLE_TASK_WORKERS} --max-requests=${SWOOLE_MAX_REQUESTS} ;

# Check the health status using the Octane status command.
HEALTHCHECK CMD php artisan octane:status --server="swoole"
