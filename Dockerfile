FROM cubicmushroom/apache_varnish

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

# Change default port 80 to 8080
ADD ./000-default.conf /etc/apache2/sites-available/000-default.conf

# Varnish config
ADD ./default.vcl /etc/varnish/default.vcl
ADD ./varnish /etc/default/varnish

ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_BACKEND_IP 127.0.0.1
ENV VARNISH_PORT 80

# Clear out /var/www/html
RUN rm -rf /var/www/html/*

# Install Flexion Discover Component
# RUN git archive --remote=git@bitbucket.org:cubicmushroom/flexion-discovery-component.git --format=gz --output="/var/www/html/flexion-discovery-component.tar.gz" staging
RUN curl --digest --user cubicmushroom:<change:password> https://bitbucket.org/cubicmushroom/flexion-discovery-component/get/staging.gz -Lo /var/www/html/flexion-discovery-component.tar.gz
RUN cd /var/www/html && tar xvf flexion-discovery-component.tar.gz && rm flexion-discovery-component.tar.gz
RUN cd /var/www/html && sudo cp -R cubicmushroom-flexion-discovery-component-*/. /var/www/html && rm -Rf cubicmushroom-flexion-discovery-component-*

## Run composer manually (or using the setup.sh script
RUN cd /var/www/html && composer install --no-scripts

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
# EXPOSE 3306
# EXPOSE 6082
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
