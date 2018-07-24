# laraveldocker 

最小化满足 Laravel 本地化开发需要。

核心的优点在于：使用国内镜像、使用国内镜像、使用国内镜像

# 软件
- [x] Nginx 1.13
- [x] PHP 7.2
- [x] MySQL 5.7
- [x] Redis
- [x] NodeJS 10.7.0
- [ ] PostgreSQL
- [x] Yarn 1.7.0
- [x] Composer
- [x] Laravel Envoy
- [x] Laravel Installer
- [ ] Lumen Installer

# 怎么使用

直接复制在项目同文件夹下，运行 `docker-compose up`

# MySQL Details

- MySQL Username = `homestead`
- MySQL Password = `secret`
- MySQL Database = `homestead`

# 设计思路说明

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322437398197.jpg)

好久没写东西，今天说一说怎么自建一个 Laravel 运行的 Docker 环境。

市面上最出名的莫过于「laradock」[https://github.com/laradock/laradock](https://github.com/laradock/laradock)

>  ![](http://ow20g4tgj.bkt.clouddn.com/2018-07-20-15320923406257.jpg)
> 
> Docker PHP development environment. 
> 使用参考：[http://laradock.io](http://laradock.io)

既然是「自建」，那我们可以参考这个，最小化满足 Laravel 运行的需要。

下面是我罗列出的基本条件：

1. 软件：PHP 7.2、Nginx、MySQL、Composer、NPM or Yarn 等等；
2. 使用国内镜像；使用国内镜像；使用国内镜像；
3. 易于扩展使用，如随时可以切换 PHP 版本，或者 Apache 和 Nginx 切换使用。

## Docker-Compose

要达到可扩展行，和「laradock」一样，使用 Docker-Compose 编排的方式，将核心的几个 image 组装在一起。

### php-fpm

这里我们使用的是「DaoCloud」加速镜像 —— `7.2-fpm-alpine`。

该版本既用 `PHP 7.2` 版本，而且 `alpine` 最小化系统，可以基于此，安装环境需要的额外工具：如，`composer`、`nodejs`、`python`、`yarn` 等。

```
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
```
其中安装 `alpine` 系统插件，我们使用 `mirrors.aliyun.com` 阿里云镜像。

`php:7.2-fpm-alpine` 具体使用，可以参考：[https://dashboard.daocloud.io/packages/019c8dce-ec80-4468-bddc-254fc62ef5c7](https://dashboard.daocloud.io/packages/019c8dce-ec80-4468-bddc-254fc62ef5c7)

### nginx

我们使用 `nginx`，主要是将网站的配置文件载入 `nginx` 中。

```bash
FROM daocloud.io/nginx:1.13-alpine

MAINTAINER coding01 <yemeishu@126.com>

ADD vhost.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www
```

剩下就是连接这些 images。最后看看 `docker-compose.yml`  文件内容：

```bash
version: '2'
services:

  # The Application
  app:
    build:
      context: ./
      dockerfile: app.dockerfile
    working_dir: /var/www
    volumes:
      - ../:/var/www
    environment:
      - "DB_PORT=3306"
      - "DB_HOST=database"
      - "REDIS_HOST=redis"
      - "REDIS_PORT=6379"

  # The Web Server
  web:
    build:
      context: ./
      dockerfile: web.dockerfile
    working_dir: /var/www
    volumes_from:
      - app
    ports:
      - 8080:80

  # The Database
  database:
    image: daocloud.io/mysql:5.7.4
    volumes:
      - dbdata:/var/lib/mysql
    environment:
      - "MYSQL_DATABASE=homestead"
      - "MYSQL_USER=homestead"
      - "MYSQL_PASSWORD=secret"
      - "MYSQL_ROOT_PASSWORD=secret"
    ports:
        - "3306:3306"

  redis:
    image: daocloud.io/library/redis:4.0.10-alpine
    command: redis-server --appendonly yes

volumes:
  dbdata:
```

## 测试一遍

### 创建 Laravel 项目

```bash
composer create-project laravel/laravel demo
```

*注：*为了做测试，可以将 `vendor` 文件夹和 `composer.lock` 文件删除。

### git clone

在 `demo` 项目相同文件夹下，`git clone` 我们自建的「laraveldocker」：

```bash
git clone https://github.com/fanly/laraveldocker.git
```
### 修改 docker-compose.yml

将 `docker-compose.yml` 文件的路径执行我们的项目：

```bash
app:
    build:
      context: ./
      dockerfile: app.dockerfile
    working_dir: /var/www
    volumes:
      - ../:/var/www
```

### build

在 `laraveldocker` 下执行构建命令:

```bash
docker-compose up
```

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-21-15321874922903.jpg)

整个速度还是蛮快的

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322343650332.jpg)

接下来进入容器内

```bash
docker exec -it de075c525528 bash
```
我们看看安装插件的效果：

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322347323680.jpg)

使用的是 `https://packagist.laravel-china.org` 国内镜像。

> 注：该镜像是由 Laravel China 社区联合 又拍云 与 优帆远扬 共同合作推出的公益项目，旨在为广大 PHP 用户提供稳定和高速的 Composer 国内镜像服务。
> 
> 值得推荐使用
> 
> 参考：[http://laravel-china.org/topics/4484/composer-mirror-use-help](http://laravel-china.org/topics/4484/composer-mirror-use-help)

使用 `yarn` 或者 `cnpm` 安装插件：

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322351935437.jpg)

生成 `Laravel key secret`：

```bash
cp .env.example .env
php artisan key:generate

Application key [base64:4A7VK6MEX7FakPLDSLji97kz/nyWUAWhW4wYn3gefsY=] set successfully.
```

运行下看看效果吧：

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322389136588.jpg)

我们接下来看看数据库连接吧，修改 `.env`：

```bash
DB_CONNECTION=mysql
DB_HOST=database
DB_PORT=3306
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=secret
```

我们使用 `php artisan make:auth` 来生成布局、注册和登录视图以及所有的认证接口的路由。同时它还会生成 `HomeController` 来处理应用的登录请求。使用 `php artisan migrate` 来载入数据。

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322404900535.jpg)

我们看看数据表：

![](http://ow20g4tgj.bkt.clouddn.com/2018-07-22-15322406474650.jpg)

至此，说明我们连接 `MySQL` 数据库 OK.

# 总结

在学习过程中，使用别人做好的 Dockerfile，虽可以直接拿来使用，但如果能自给自足，那最好不过了。

通过自建 docker 开发环境过程中，也能让自己学到更多。接下来还会不断完善，最小化满足开发需要。

代码已放在 `github` 上，欢迎参考和提出 `issue`：

> [https://github.com/fanly/laraveldocker](https://github.com/fanly/laraveldocker)

最后也可以看之前对 「Laradock」的使用文章：

[通过 Laradock 学 Docker —— 配置篇](https://mp.weixin.qq.com/s/Xmk-Zao-h3RWa6gQ8AiI7w)

[通过 Laradock 学 Docker-HTTPS](https://mp.weixin.qq.com/s/JpYseVk46gA-OqBA1q02kg)