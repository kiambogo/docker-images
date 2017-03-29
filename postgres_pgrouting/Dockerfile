# Dockerfile for creating container with Postgres 9.6, postgis 2.3, osm2pgrouting2.2.0, and pgRouting 2.3.2

FROM ubuntu:16.04
MAINTAINER Christopher Poenaru <kiambogo@gmail.com>

ADD dependencies/Waterloo.osm /map_data.osm
ADD dependencies/pgrouting.sql /pgrouting_functions.sql

RUN apt-get update && apt-get upgrade -y && apt-get install -y
RUN apt-get install -y vim wget curl build-essential libboost-dev expat libexpat1-dev \
                       libboost-program-options-dev software-properties-common \
                       python-software-properties
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main" >> /etc/apt/sources.list'
RUN wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
RUN apt-get update

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.6
RUN apt-get install -y python-software-properties software-properties-common postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 postgresql-server-dev-9.6

WORKDIR /tmp

# Install cmake3.2.2 from source
RUN wget http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz \
  && tar xf cmake-3.2.2.tar.gz && cd cmake-3.2.2 && ./configure && make && make install

# Installs Postgres 9.6 + Postgis 2.3
RUN apt-get install -y postgresql-9.6 postgresql-9.6-postgis-2.3 postgresql-contrib-9.6 postgis
# Install pgRouting 2.3.3
RUN apt-get install -y postgresql-9.5-pgrouting
# Install osm2pgrouting
RUN wget https://github.com/pgRouting/osm2pgrouting/archive/v2.2.0.tar.gz  \
  && tar xzf v2.2.0.tar.gz \
  && cd osm2pgrouting-2.2.0 \
	&& cmake -H. -Bbuild -DPOSTGRESQL_INCLUDE_DIR:PATH=/usr/include/postgresql/ \
  && cd build && make && make install

# Write start script to start postgres
RUN echo """#!/bin/bash \n \
         /usr/lib/postgresql/9.6/bin/postgres -D /var/lib/postgresql/9.6/main -c config_file=/etc/postgresql/9.6/main/postgresql.conf""" >> /start.sh
RUN chmod +x /start.sh

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.6`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `maps` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start \
    && psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" \
    && createdb -O docker maps \
    && psql --command "CREATE EXTENSION postgis;" maps \
    && psql --command "CREATE EXTENSION pgrouting;" maps \
    && osm2pgrouting -f /map_data.osm --dbname maps --username docker --password docker --clean \
    && psql -f /pgrouting_functions.sql --dbname maps

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.6/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

# Expose the Postgres port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

CMD ["/start.sh"]
