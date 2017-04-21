FROM ubuntu:16.04

RUN apt-get update --fix-missing
RUN apt-get install -y curl vim npm telnet wget
RUN apt-get install -y libboost-all-dev subversion git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libtiff5-dev
RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev mapnik-utils python-mapnik libmapnik-dev
RUN apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted ttf-unifont

# Install Mapnik
RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik

# Install Carto
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && apt-get install -y nodejs
RUN apt-get install -y nodejs
RUN npm install -g carto

# Install Modtile
WORKDIR /tmp
RUN git clone git://github.com/SomeoneElseOSM/mod_tile.git &&\
    cd mod_tile &&\
    ./autogen.sh &&\
    ./configure &&\
    make &&\
    make install &&\
    make install-mod_tile &&\
    ldconfig &&\
    cd /tmp &&\
    rm -rf mod_tile

# Install the Mapnik stylesheet
WORKDIR /usr/local/src
RUN wget https://github.com/mapbox/osm-bright/zipball/master && unzip master && rm master && mv mapbox* osm-bright
# Install the coastline data

RUN cd /usr/local/src/osm-bright && mkdir shp && cd shp && wget http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip
RUN cd /usr/local/src/osm-bright/shp && wget http://data.openstreetmapdata.com/land-polygons-split-3857.zip
RUN cd /usr/local/src/osm-bright/shp && mkdir ne_10m_populated_places && cd ne* &&  wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip && unzip '*.zip'
RUN cd /usr/local/src/osm-bright/shp && unzip '*.zip'
ADD configure.py /usr/local/src/osm-bright/
RUN cd osm-bright && chmod +x configure.py && ./configure.py && ./make.py
ADD palette.mss /usr/local/src/osm-bright/osm-bright/OSMBright/
ADD roads.mss /usr/local/src/osm-bright/osm-bright/OSMBright/
ADD project.mml /usr/local/src/osm-bright/osm-bright/OSMBright/
RUN cd osm-bright/osm-bright/OSMBright && carto project.mml > mapnik.xml

# Configure renderd
ADD renderd.conf.sed /tmp/
RUN cd /usr/local/etc && sed --file /tmp/renderd.conf.sed --in-place renderd.conf

# Create the files required for the mod_tile system to run
RUN mkdir /var/run/renderd && chown www-data: /var/run/renderd
RUN mkdir /var/lib/mod_tile && chown www-data /var/lib/mod_tile

# Configure mod_tile
ADD mod_tile.load /etc/apache2/mods-available/
ADD mod_tile.conf /etc/apache2/mods-available/
RUN a2enmod mod_tile

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add startup script
ADD startup.sh /startup.sh
RUN chmod +x /startup.sh

# Expose the webserver
EXPOSE 80

CMD "/startup.sh"
