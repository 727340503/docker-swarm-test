FROM php:7-fpm-alpine
RUN set -xe \
# "安装 php 以及编译构建组件所需包"
# "运行依赖"
    && apk add --no-cache \
        freetype \
        libjpeg-turbo \
        libmcrypt \
        libpng \
# "构建依赖"
    && apk add --no-cache \
        --virtual .build-deps \
        $PHPIZE_DEPS \
        php5-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
# "编译安装 php 组件"
    && docker-php-ext-install iconv mcrypt mysqli pdo pdo_mysql zip \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
# "清理"
    && apk del .build-deps \
    && docker-php-source delete

COPY ./php.conf /usr/local/etc/php/conf.d/php.conf
COPY ./site /usr/share/nginx/html
