#!/bin/bash

# reenable password authentication
sed -i "s/host all all all trust/host all all all md5/" /var/lib/postgresql/data/pg_hba.conf
