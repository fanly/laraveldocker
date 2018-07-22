FROM daocloud.io/php:7.2-fpm-alpine

MAINTAINER coding01 <yemeishu@126.com>

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        curl-dev \
        imagemagick-dev \
        libtool \
        libxml2-dev \
        postgresql-dev \
        sqlite-dev \
    && apk add --no-cache \
        curl \
        git \
        imagemagick \
        mysql-client \
        postgresql-libs \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-install \
        curl \
        iconv \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pcntl \
        tokenizer \
        xml \
        zip \
    && curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    && apk del -f .build-deps

# 修改 composer 为国内镜像
RUN composer config -g repo.packagist composer https://packagist.laravel-china.org

# install prestissimo
RUN composer global require "hirak/prestissimo"

# install laravel envoy
RUN composer global require "laravel/envoy"

#install laravel installer
RUN composer global require "laravel/installer"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk update && apk add -u nodejs libpng-dev python

ENV PATH /root/.yarn/bin:$PATH

RUN apk update \
  && apk add curl bash binutils tar \
  && rm -rf /var/cache/apk/* \
  && /bin/bash \
  && touch ~/.bashrc \
  && curl -o- -L https://yarnpkg.com/install.sh | bash \
  && yarn config set registry 'https://registry.npm.taobao.org' \
  && npm install -g cnpm --registry=https://registry.npm.taobao.org

WORKDIR /var/www