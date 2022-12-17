FROM ubuntu:22.04

LABEL maintainer="Ishan Jayamannne <ishanjmails@gmail.com>"
LABEL version="4.0"
LABEL description="Laravel Circle ci php8.1-fpm with node 14"
LABEL "com.example.vendor"="Ishannz"

ENV NVM_DIR=/root/.nvm
ENV PHP81_CONF /etc/php/8.1/fpm/php.ini
ENV FPM81_CONF /etc/php/8.1/fpm/pool.d/www.conf


ENV DEBIAN_FRONTEND=noninteractive 

ENV NVM_VERSION v0.35.0

RUN apt-get update

# Required to add yarn package repository
RUN apt-get install -y apt-transport-https gnupg curl

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

RUN apt update && apt install -y software-properties-common && add-apt-repository ppa:ondrej/php

RUN apt-get update && apt-get install -y \
        libbz2-dev \
        libsodium-dev \
        git \
        unzip \
        wget \
        libpng-dev \
        libgconf-2-4 \
        libfontconfig1 \
        chromium-browser \
        libgtk2.0-0\
        libgtk-3-0 \
        libnotify-dev \
        libgconf-2-4 \
        libnss3 \
        libxss1 \
        libasound2 \
        libxtst6 \
        xauth \
        xvfb \
        yarn \
        wget \
        libzip-dev \
        nginx \
        php8.1-fpm \
        php8.1-cli \
        php8.1-dev 


RUN apt-get update && apt-get install -y \
    php8.1-mysql \       
    php8.1-common \
    php8.1-mbstring \
    php8.1-curl \
    php8.1-gd \
    php8.1-mysql \
    php8.1-zip \
    php8.1-intl \
    php8.1-xml \
    php-pear \
    mysql-client \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${PHP81_CONF} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${PHP81_CONF} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${PHP81_CONF} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${PHP81_CONF} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${PHP81_CONF} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.1/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${FPM81_CONF} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${FPM81_CONF} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${FPM81_CONF} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${FPM81_CONF} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${FPM81_CONF} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${FPM81_CONF}


# install Chromebrowser
RUN \
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
  apt-get update && \
  apt-get install -y dbus-x11 google-chrome-stable && \
  rm -rf /var/lib/apt/lists/*

RUN pecl install redis xdebug-3.2.0

RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash

RUN . ~/.nvm/nvm.sh && \
        nvm install lts/carbon && \
        nvm alias default lts/carbon && \
        nvm install 12.21.0 && \
        nvm install 10 && \
        nvm install 14 && \
        nvm use 14 && \
        nvm alias default 14

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    mv composer.phar /usr/local/bin/composer && \
    php -r "unlink('composer-setup.php');" && \
    composer --version

# Override nginx's default config
COPY default /etc/nginx/sites-available

RUN service nginx stop
RUN service nginx start

RUN service php8.1-fpm stop
RUN service php8.1-fpm start

# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM xterm
# avoid million NPM install messages
ENV npm_config_loglevel warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm true

EXPOSE 80/tcp
EXPOSE 80/udp
    