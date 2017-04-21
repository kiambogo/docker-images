#!/bin/bash

service apache2 start
renderd -f -c /usr/local/etc/renderd.conf
