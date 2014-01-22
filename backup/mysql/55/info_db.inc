#!/bin/bash

#* MySQL login user name *#
DB_USER="userid"

#* MySQL login PASSWORD name *#
DB_PASS="password"

#* MySQL login HOST name *#
DB_HOST="localhost"

#* MySQL binaries *#
DB_TYPE="$(which mysql)"
DB_SQLDUMP="$(which mysqldump)"
DB_PARAM=" --single-transaction --master-data=2 --triggers --routines --events"