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
RUN apt-get update
RUN apt-get -y upgrade

# Bear Necessities
RUN apt-get -y install apache2 curl git libapache2-mod-php5 lsb-release mysql-client openssh-server php5-mysql php-apc pwgen python-setuptools ssh-client sudo unzip  

# PHP Modules
RUN apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# Symfony
RUN apt-get -y install php5-gd php5-intl

# Varnish
RUN apt-get install -y varnish

# Supervisor
RUN apt-get install -y supervisor

# SSHD
RUN mkdir /var/run/sshd

# Apache2 config
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# Change default port 80 to 8080
RUN sed -i -e "s/80/8080/g" /etc/apache2/sites-available/000-default.conf
RUN sed -i -e "s/80/8080/g" /etc/apache2/ports.conf

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

# Install Symfony App
## RUN composer create-project symfony/framework-standard-edition /var/www/html 2.5.*
## RUN cd /var/www/html && composer install
## Commented out since there's some odd bug and I don't know to comment on Symfony issues...
## Cannot rename "/var/www/html/app/cache/dev" to "/var/www/html/app/cache/dev_old". 
## but it looks like a permission error...
## 
## So: here's an example pulling a tarball
# These can also be RUN curl -o for retrieval
ADD http://ftp.drupal.org/files/projects/drupal-7.28.tar.gz /var/www/html/drupal-7.28.tar.gz
RUN cd /var/www/html/ && tar xvf drupal-7.28.tar.gz && rm drupal-7.28.tar.gz
## RUN mv /var/www/html/drupal-7.28/* ..
## RUN mv /var/www/html/drupal-7.28/.htaccess ..
## RUN rmdir /var/www/html/drupal-7.28
RUN chown -R www-data:www-data /var/www/html/drupal-7.28

# 
EXPOSE 22
EXPOSE 80
EXPOSE 6082
EXPOSE 8080

CMD ["/usr/bin/supervisord"]
