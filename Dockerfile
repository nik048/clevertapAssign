FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN set -eux; \
    apt update; \
    apt install -y apache2 apache2-utils; \
    mkdir -p /var/www/html; \
    apt install -y php libapache2-mod-php php-mysql; \
    rm /var/www/html/index.html; \
    rm -rf /var/lib/apt/lists/*;

COPY ./wordpress /var/www/html/

RUN set -eux; \
    mkdir /var/www/html/wp-content/uploads; \
    chown -R www-data:www-data /var/www/html;
RUN echo $PATH
CMD ["apache2ctl", "-D", "FOREGROUND"]

EXPOSE 80

