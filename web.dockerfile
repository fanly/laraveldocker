FROM daocloud.io/nginx:1.13-alpine

MAINTAINER coding01 <yemeishu@126.com>

ADD vhost.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www