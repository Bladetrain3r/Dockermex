
#!/bin/sh
apk add --no-cache \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    geoip-dev \
    g++ \
    git \
    libtool \
    automake \
    autoconf \
    file

git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity &&\
cd ModSecurity &&\
git submodule init && git submodule update
./build.sh && ./configure && make && make install

# Grab current version of NGINX
cd /etc/nginx
./configure --add-dynamic-module=/path/to/ModSecurity-nginx --with-compat
nginx -v
nginx -v 2>&1 | awk -F/ '{print $2}' > /tmp/nginx_version
cat /tmp/nginx_version 
cd /
wget http://nginx.org/download/nginx-$(cat /tmp/nginx_version).tar.gz && tar zxvf nginx-$(cat /tmp/nginx_version).tar.gz
ls
cd nginx-1.27.2/
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules
cd /
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
cd nginx-1.27.2/
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules
ls objs/
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/
ls /etc/nginx/modules/
vim /etc/nginx/conf.d/default.conf 
vi /etc/nginx/conf.d/default.conf 
vi /etc/nginx/nginx.conf 
ls /etc/nginx/conf.d
vi /etc/nginx/nginx.conf
cd ..
rm -rf nginx-1.27.2
cd /etc/nginx/modules/
ls
cd ..
ls
mkdir /etc/nginx/modsecurity
cd /etc/nginx/modsecurity
git clone https://github.com/coreruleset/coreruleset.git
cp coreruleset/crs-setup.conf.example crs-setup.conf
vim main.conf
vi main.conf
sudo nginx -t
nginx -t
vi /etc/nginx/nginx.conf 
vi /etc/nginx/conf.d/default.conf 
sudo !!
vi /etc/nginx/conf.d/default.conf 
