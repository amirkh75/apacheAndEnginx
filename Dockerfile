FROM ubuntu:20.04


# RUN DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Minsk
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# update and install some common packages.
RUN apt update -y && \
    apt upgrade -y && \
    # Install common / shared packages
    apt-get install -y \
    curl \
    git \
    zip \
    unzip \
    vim \
    locales \
    wget \
    net-tools \
    software-properties-common


# Install Apache, PHP-FPM and libapache2-mod-fastcgi.
RUN apt -y install apache2
RUN wget http://mirrors.kernel.org/ubuntu/pool/multiverse/liba/libapache-mod-fastcgi/libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb && \
    dpkg -i libapache2-mod-fastcgi_2.4.7~0910052141-1.2_amd64.deb
RUN apt install -y php7.4 php7.4-cli php7.4-fpm php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring \
    php7.4-curl php7.4-xml php-pear php7.4-bcmath libapache2-mod-php7.4
# We will be adding a configuration block for mod_fastcgi which depends on mod_action.

# copy configs and codes.
COPY apache apache
COPY nginx nginx


RUN cp apache/mods-enabled/php-fpm.conf /etc/apache2/conf-available/php-fpm.conf
RUN a2enconf php7.4-fpm
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod actions

# set Apache to listen port 8080.
RUN cp /etc/apache2/ports.conf /etc/apache2/ports.conf.default && \
    echo "Listen 8080" | tee /etc/apache2/ports.conf && \
    a2dissite 000-default && \
    rm -rf /etc/apache2/sites-available/000-default.conf


# Creating Virtual Hosts for Apache (foobar.net). http://foobar.net:8080
RUN mkdir /var/www/foobar.net
RUN cp apache/var/www/foobar.net/index.html /var/www/foobar.net/index.html
RUN cp apache/var/www/foobar.net/info.php /var/www/foobar.net/info.php
RUN cp apache/sites-available/foobar.net.conf /etc/apache2/sites-available/foobar.net.conf
RUN a2ensite foobar.net


# Creating Virtual Hosts for Apache (test.io). http://test.io:8080
RUN mkdir /var/www/test.io
RUN cp apache/var/www/test.io/index.html /var/www/test.io/index.html
RUN cp apache/var/www/test.io/info.php /var/www/test.io/info.php
RUN cp apache/sites-available/test.io.conf /etc/apache2/sites-available/test.io.conf
RUN a2ensite test.io




# ----------------------------------------

RUN apt -y install nginx && \
    rm /etc/nginx/sites-enabled/default && \
    mkdir -v /usr/share/nginx/example.com /usr/share/nginx/sample.org

RUN echo "<h1 style='color: green;'>Example.com from enginx</h1>" | tee /usr/share/nginx/example.com/index.html && \
    echo "<h1 style='color: red;'>Sample.org from enginx</h1>" | tee /usr/share/nginx/sample.org/index.html && \
    echo "<?php phpinfo(); ?>" | tee /usr/share/nginx/example.com/info.php && \
    echo "<?php phpinfo(); ?>" | tee /usr/share/nginx/sample.org/info.php

RUN cp nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com
RUN cp nginx/sites-available/sample.org /etc/nginx/sites-enabled/sample.org




# Nginx as reverse proxy to Apache.
RUN cp nginx/sites-available/apache /etc/nginx/sites-enabled/apache


# config test.
RUN nginx -t

RUN service nginx restart

# In this step you’ll install an Apache module called mod\_rpaf which rewrites the values of REMOTE_ADDR, HTTPS and HTTP_PORT based on the values provided by a reverse proxy. Without this module, some PHP applications would require code changes to work seamlessly from behind a proxy.
RUN apt -y install libapache2-mod-rpaf apache2-dev && \
    a2enmod rpaf


# test configs.
RUN apachectl -t


# reload Apache (base on initd system).
RUN service apache2 restart

# By default, simply start apache.  / my usual error : You have typographic quotes in CMD (“ ”), use straight quotes ("). – Dan Lowe
CMD ["apache2ctl", "-D", "FOREGROUND"]
# CMD ["nginx", "-g", "daemon off;"]

    