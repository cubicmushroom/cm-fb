FROM ubuntu:14.04

# As per https://github.com/dotcloud/docker/issues/1024
# This is intended as a temporary workaround but is pending
# fix from docker
#
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# This surpresses interactive package install. Comment out for prompts
ENV DEBIAN_FRONTEND noninteractive

# Housekeeping
RUN apt-get clean
RUN apt-get update
RUN apt-get -y upgrade

# Bear Necessities
RUN apt-get -y install apache2 curl git libapache2-mod-php5 lsb-release mysql-client openssh-server php5-mysql php-apc pwgen python-setuptools ssh-client sudo unzip  

# PHP Modules
RUN apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-gd

# Symfony
RUN apt-get -y install php5-gd php5-intl

# Don't start Varnish after install, leave that to supervisord
RUN echo '#!/bin/sh\nexit 101' > usr/sbin/policy-rc.d
RUN sudo chmod +x /usr/sbin/policy-rc.d

# Varnish
RUN apt-get install -y varnish

# Undo the above
RUN rm /usr/sbin/policy-rc.d

# Supervisor
RUN apt-get install -y supervisor

# SSHD
# RUN mkdir /var/run/sshd

# Apache2 config
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# Change default port 80 to 8080
RUN sed -i -e "s/80/8080/g" /etc/apache2/ports.conf
## RUN sed -i -e "s/80/8080/g" /etc/apache2/sites-available/000-default.conf
ADD ./000-default.conf /etc/apache2/sites-available/000-default.conf
RUN sudo a2enmod rewrite

# Varnish config
# http://symfony.com/doc/current/cookbook/cache/varnish.html
# These can also be RUN curl -o for retrieval

ADD ./default.vcl /etc/varnish/vcl/default.vcl
ADD ./varnish /etc/default/varnish

ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_BACKEND_IP 172.17.42.1
ENV VARNISH_PORT 80

# php-fpm config (If we switch from Apache mod php)
## RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini

## Make max_filesize sensible
## RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 8M/g" /etc/php5/fpm/php.ini

## Uncomment and change next line if needed
## RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
## RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
## RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
## RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Supervisor Config
## RUN /usr/bin/easy_install supervisor
## RUN /usr/bin/easy_install supervisor-stdout
# This can also be RUN curl -o for retrieval
ADD ./supervisord.conf /etc/supervisord.conf

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Clear out /var/www/html
RUN rm -rf /var/www/html/*

# MySQL/MariaDB/etc

RUN apt-get -y install mysql-server
RUN mysql_install_db > /dev/null 2>&1
ADD mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

# !!!This leaves NO ROOT PASSWORD FOR MYSQL!!!

# Install Symfony App
## RUN composer create-project symfony/framework-standard-edition /var/www/html 2.5.*
## RUN cd /var/www/html && composer install
## Commented out since there's some odd bug and I don't know to comment on Symfony issues...
## Cannot rename "/var/www/html/app/cache/dev" to "/var/www/html/app/cache/dev_old". 
## but it looks like a permission error...
## 

# Install Flexion Discover Component
# RUN git archive --remote=git@bitbucket.org:cubicmushroom/flexion-discovery-component.git --format=gz --output="/var/www/html/flexion-discovery-component.tar.gz" staging
# Edited out by Jak for Testing:
### RUN curl --digest --user cubicmushroom:<password> https://bitbucket.org/cubicmushroom/flexion-discovery-component/get/staging.gz -Lo /var/www/html/flexion-discovery-component.tar.gz
### RUN cd /var/www/html && tar xvf flexion-discovery-component.tar.gz && rm flexion-discovery-component.tar.gz
### RUN cd /var/www/html && sudo cp -R cubicmushroom-flexion-discovery-component-*/. /var/www/html && rm -Rf cubicmushroom-flexion-discovery-component-*

## Run composer manually (or using the setup.sh script
### RUN cd /var/www/html && composer install --no-scripts
# EOEdited

RUN chown -R www-data:www-data /var/www/html

# 

EXPOSE 80
EXPOSE 3306
EXPOSE 6082
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
