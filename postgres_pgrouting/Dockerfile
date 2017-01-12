# Dockerfile for creating container with Postgres 9.5, postgis 2.2, osm2pgrouting2.2.0, and pgRouting 2.3.2

FROM ubuntu
MAINTAINER Christopher Poenaru <kiambogo@gmail.com>

ENV MAPS_URL=https://raw.githubusercontent.com/kiambogo/docker-images/master/postgres_pgrouting/dependencies/Waterloo.osm

RUN apt-get update && apt-get upgrade -y && apt-get install -y vim wget curl
RUN apt-get install -y build-essential libboost-dev expat libexpat1-dev libboost-program-options-dev

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.5
RUN apt-get install -y python-software-properties software-properties-common postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5 postgresql-server-dev-9.5

WORKDIR /tmp

# Install cmake3.2.2 from source
RUN wget http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz \
  && tar xf cmake-3.2.2.tar.gz && cd cmake-3.2.2 && ./configure && make && make install

# Install Postgis 2.2
RUN apt-get install -y postgis postgresql-9.5-postgis-2.2
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
         /usr/lib/postgresql/9.5/bin/postgres -D /var/lib/postgresql/9.5/main -c config_file=/etc/postgresql/9.5/main/postgresql.conf""" >> /start.sh
RUN chmod +x /start.sh

# Download maps data
RUN curl -o /maps.sql ${MAPS_URL}

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.5`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `maps` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN /etc/init.d/postgresql start \
    && psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" \
    && createdb -O docker maps \
    && psql --command "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;" maps \
    && psql --command "CREATE EXTENSION pgrouting;" maps \
    && osm2pgrouting -f /maps.sql --dbname maps --username docker --password docker --clean

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.5/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Expose the Postgres port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

CMD ["/start.sh"]
