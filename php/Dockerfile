FROM php:8.4-fpm

RUN apt-get update && apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libldap2-dev \
    libxslt1-dev \
    wget \
    unzip \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    gd \
    intl \
    opcache \
    soap \
    xsl \
    zip \
    exif

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap

RUN pecl install redis && docker-php-ext-enable redis

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN { \
    echo 'memory_limit = 256M'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_execution_time = 600'; \
    echo 'max_input_vars = 5000'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 8000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'session.cookie_httponly = 1'; \
    echo 'session.cookie_secure = 0'; \
    echo 'session.use_only_cookies = 1'; \
    echo 'cgi.fix_pathinfo = 1'; \
} > /usr/local/etc/php/conf.d/moodle.ini

RUN mkdir -p /var/moodledata && \
    chown -R www-data:www-data /var/moodledata && \
    chmod 777 /var/moodledata

WORKDIR /var/www/html

# Copy initialization script first (as root)
COPY --chown=www-data:www-data docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Download and extract Moodle (as root for permissions)
RUN echo "Starting Moodle download..." && \
    wget --no-check-certificate https://download.moodle.org/download.php/direct/stable500/moodle-latest-500.tgz -O /tmp/moodle.tgz && \
    echo "Download completed, extracting..." && \
    tar -xzf /tmp/moodle.tgz --strip-components=1 -C /var/www/html && \
    echo "Extraction completed, setting permissions..." && \
    rm /tmp/moodle.tgz && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    echo "Moodle setup completed" && \
    ls -la /var/www/html/index.php

USER www-data

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]