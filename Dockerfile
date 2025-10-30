FROM alpine:latest

ENV PHP_VERSION="84"
ENV CACTI_VERSION="1.2.30" 
ENV CACTI_PATH="/var/www/html/cacti"

RUN apk --no-cache upgrade && \
	apk add --no-cache php${PHP_VERSION} apache2 php${PHP_VERSION}-apache2 php${PHP_VERSION}-mysqli rrdtool net-snmp php${PHP_VERSION}-pdo php${PHP_VERSION}-pdo_mysql \
	php${PHP_VERSION}-session php${PHP_VERSION}-xml php${PHP_VERSION}-posix php${PHP_VERSION}-sockets php${PHP_VERSION}-ldap php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-gd php${PHP_VERSION}-snmp php${PHP_VERSION}-gmp \
	mariadb-client rrdtool net-snmp net-snmp-tools git

WORKDIR /home/

RUN wget https://files.cacti.net/cacti/linux/cacti-${CACTI_VERSION}.tar.gz && \
	mkdir -p ${CACTI_PATH} && tar -xvf cacti-${CACTI_VERSION}.tar.gz && mv cacti-${CACTI_VERSION}/* ${CACTI_PATH}

COPY httpd.conf /etc/apache2

COPY launch.sh /usr/local/bin/launch.sh

RUN chmod +x /usr/local/bin/launch.sh

RUN echo "*/1 * * * * php84 ${CACTI_PATH}/poller.php >/dev/null 2>&1" >> /etc/crontabs/root

RUN printf "session.save_path = \"/var/lib/php/sessions\"\nsession.cookie_path = \"/\"\nsession.use_strict_mode = 0" >> /etc/php84/conf.d/00-session.ini

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/launch.sh"]
