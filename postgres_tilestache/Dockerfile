# Dockerfile for creating container with Postgres 9.5, postgis 2.2, and tilestache 1.49
# This will allow users to interact with map data stored in postgres through tilestache's HTTP API

FROM ubuntu
MAINTAINER Christopher Poenaru <kiambogo@gmail.com>

# URL of maps data dumped from postgres (sql format)
ENV MAPS_URL=https://raw.githubusercontent.com/kiambogo/docker-images/master/postgres_tilestache/dependencies/maps.sql
# URL of tilestache config to use
ENV TILESTACHE_CONFIG_URL=https://raw.githubusercontent.com/kiambogo/docker-images/master/postgres_tilestache/dependencies/tilestache.cfg

RUN apt-get update && apt-get install -y vim wget curl

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.5
RUN apt-get install -y python-software-properties software-properties-common postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5

# Install Python + Pip
RUN apt-get install -y python-pip

# Install Postgis 2.2
RUN apt-get install -y postgis postgresql-9.5-postgis-2.2
RUN apt-get install -y python-psycopg2

# Install reqs for Tilestache
RUN pip install -U Pillow modestmaps simplejson werkzeug uuid mapnik shapely

# Install Tilestache
RUN curl -o tilestache.tar.gz http://tilestache.org/download/TileStache-1.49.8.tar.gz
RUN tar xzf tilestache.tar.gz && cd TileStache-1.49.8 && python setup.py install && cd ../
RUN rm tilestache.tar.gz

# Download maps data
RUN curl -o maps.sql ${MAPS_URL}
# Download tilestache config
RUN curl -o /tilestache.cfg ${TILESTACHE_CONFIG_URL}

# Write start script to start postgres and tilestache together
RUN echo """#!/bin/bash \n \
          /etc/init.d/postgresql start \n \
          tilestache-server.py -i 0.0.0.0 -c /tilestache.cfg""" >> start.sh
RUN chmod +x /start.sh

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.5`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `maps` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker maps &&\
    psql --command "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;" maps &&\
    psql -d maps -f maps.sql

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.5/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Expose the Tilestache port
EXPOSE 8080

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

CMD ["/start.sh"]
