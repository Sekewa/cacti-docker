# cacti-docker
Cacti in container, without Mariadb in it
# 🌵 cacti-docker 🐳
This is a container that only has cacti and base poller in it, if you want to run it you'll need to have in the same subnet a MariaDB container.

## About the environment variables

For now there is only three environment variable working :

| ENV| USES       |
|------|----------------------------------|
| HOST | host name of your database       |
| USER | name of the user on the database |
| PASS | password of the user             |

If they are not set, by default they keep the base value from cacti/include/config.php.dist :

| ENV| VALUES       |
|------|----------------------------------|
| HOST | localhost       |
| USER | cactiuser |
| PASS | cactiuser             |

## About MariaDB (MySQL 🐬)

On your MariaDB container, you'll need a database named *cacti*, so cacti can put the base scheme in it.

## Docker-compose example

here is a little example of what your docker-compose would look like :


``` YAML
services:
    mariadb:
        image: mariadb:11
        environment:
            MYSQL_ROOT_PASSWORD: rootpass
            MYSQL_DATABASE: cacti
            MYSQL_USER: cactiuser
            MYSQL_PASSWORD: cactipass
        volumes:
            - mariadb_data:/var/lib/mysql
        
    cacti:
        image: elmaa/cacti-docker
        depends_on:
            - mariadb
        environment:
            HOST: mariadb
            USER: cactiuser
            PASS: cactipass
        ports:
            - "8080:80"
volumes:
    mariadb_data:
```

## First connection

The first time you'll connect to cacti, don't forget the user and password :
- user, admin
- password, admin

After using them cacti will ask to change the password and you'll be set to use cacti !

## Adding plugins

If you want to add plugins in cacti, just add this line in your docker-compose :
``` YAML
servies:
    ...
    cacti:
    ...
        volumes:
            - ./plugins:/var/www/html/cacti/plugins
```

The plugin name can start by 'plugin_*', if so no need to change the name, the container will do it by itself.