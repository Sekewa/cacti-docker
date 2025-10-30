#!/bin/sh
set -e

mkdir -p ${CACTI_PATH}/log
mkdir -p /var/lib/php/sessions

chown -R apache:apache ${CACTI_PATH}/log
chmod -R 755 ${CACTI_PATH}/log
chown -R apache:apache /var/lib/php/sessions
chmod 700 /var/lib/php/sessions
chown -R apache:apache ${CACTI_PATH}

cp ${CACTI_PATH}/include/config.php.dist ${CACTI_PATH}/include/config.php

sed -i -e 's/\/cacti\//\//g' ${CACTI_PATH}/include/config.php

if [ -z ${USER} ] ; then
	USER=${USER}
else
	sed -i -e "s/cactiuser/${USER}/g" ${CACTI_PATH}/include/config.php
fi

if [ -z ${PASS} ] ; then
	PASS=${PASS}
else
	sed -i -e "s/\$database_password = \'cactiuser\'/\$database_password = \'${PASS}\'/g" ${CACTI_PATH}/include/config.php
fi

if [ -z ${HOST} ] ; then
	HOST=localhost
else
	sed -i -e "s/localhost/${HOST}/g" ${CACTI_PATH}/include/config.php
fi

if [ -z ${PORT} ] ; then
	PORT=3306
else
	sed -i -e "s/3306/${PORT}/g" ${CACTI_PATH}/include/config.php
fi

# on attend que mariadb soit disponible
until mariadb-admin ping -h ${HOST} -u ${USER} -p${PASS} --silent; do
	sleep 2
	echo "retrying..."
done

TABLES=$(mariadb -h ${HOST} -u ${USER} -p${PASS} -e "USE cacti; SHOW TABLES;")

if [ "$TABLES" = "" ] ; then
	echo "Importing cacti.sql..."
	mariadb -h ${HOST} -u ${USER} -p${PASS} cacti < ${CACTI_PATH}/cacti.sql
	
	echo "Setting correct version..."
	mariadb -h ${HOST} -u ${USER} -p${PASS} cacti -e "UPDATE version SET cacti = '1.2.30' WHERE cacti = 'new_install';"

	mariadb -h mariadb -u ${USER} -p${PASS} cacti -e "
	UPDATE settings SET value = '/usr/bin/php84' WHERE name = 'path_php_binary';
	UPDATE settings SET value = '/usr/bin/rrdtool' WHERE name = 'path_rrdtool';
	UPDATE settings SET value = '/usr/bin/snmpwalk' WHERE name = 'path_snmpwalk';
	UPDATE settings SET value = '/usr/bin/snmpget' WHERE name = 'path_snmpget';
	UPDATE settings SET value = '/usr/bin/snmpbulkwalk' WHERE name = 'path_snmpbulkwalk';
	UPDATE settings SET value = '/usr/bin/snmpgetnext' WHERE name = 'path_snmpgetnext';
	UPDATE settings SET value = '/var/www/html/cacti' WHERE name = 'path_webroot';"
	echo "Database initialized"
fi

echo "Starting Apache..."

crond

exec /usr/sbin/httpd -D FOREGROUND
