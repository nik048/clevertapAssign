FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true


RUN set -eux; \
    apt update; \
    apt install -y apache2 apache2-utils; \
    mkdir -p /var/www/html; \
    apt install -y php libapache2-mod-php php-mysql; \
    apt install -y mariadb-server mariadb-client; \
    ## Installing and setting mysql in Dockerfile for simplicity. 
    ##It'll expose the password
    service mysql start && \
    mysql -u root -e "CREATE DATABASE wordpress_db;" && \
    mysql -u root -e "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'password';" &&\
    mysql -u root -e "GRANT ALL ON wordpress_db.* TO 'wp_user'@'localhost' IDENTIFIED BY 'password';"; \
    rm /var/www/html/index.html; \
    rm -rf /var/lib/apt/lists/*;

COPY ./wordpress /var/www/html/

RUN set -eux; \
    mkdir /var/www/html/wp-content/uploads; \
    chown -R www-data:www-data /var/www/html;

ENV WORDPRESS_DB_HOST localhost
ENV WORDPRESS_DB_NAME wordpress_db
ENV WORDPRESS_DB_PASSWORD "password"
ENV WORDPRESS_DB_USER wp_user

CMD ["sh", "-c", "service mysql start && apache2ctl -D FOREGROUND"]

EXPOSE 80

