#!/bin/sh

set -e
set -u

POSTGRESQLUSER="postgres"
POSTGRESQLHOST="localhost"

BACKUPDIR="/tmp/postgresql-backup-datastore"
# 25 days (24 * 25 = 600 hours)
SAVED=600

LOCKFILE="/var/run/postgresql_backup.lock"
RETRIES=3
SLEEPTIME=15
# 2 hours (60 * 60 * 2 = 7200sec)
LOCKTIMEOUT=7200

LOGGER="$(which logger)"
LOGGER_CMD="${LOGGER} -p cron.info"
BK_DAYS=5

ALL_DUMP_DAY1=01
ALL_DUMP_DAY2=20

##########################
#
# function
#
##########################

SetLOG_HEADER()
{
  FILENM=`basename $0`
  MSG=$1

  LOG_DATE=`date '+%Y-%m-%d'`
  LOG_TIME=`date '+%H:%M:%S'`

  STR=$(printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}")

  ${LOGGER_CMD} ${STR}
}

SetLOG_FOOTER()
{
  FILENM=`basename $0`
  MSG=$1

  LOG_DATE=`date '+%Y-%m-%d'`
  LOG_TIME=`date '+%H:%M:%S'`

  STR=$(printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}")

  ${LOGGER_CMD} ${STR}
}

##### MAIN ######

# log write
`SetLOG_HEADER "postgres dump start"`

# Require lockfile command in procmail package.
lockfile -${SLEEPTIME} -r $RETRIES -l $LOCKTIMEOUT $LOCKFILE >/dev/null 2>&1
if [ $? -ne 0 ] ; then
    # lock failed.
    ERRMSG="PostgreSQL backup - Still running."
    echo $ERRMSG
    exit 1
fi

SELFID=`id | sed -e 's/uid=//' -e 's/(.*//'`
if [ $SELFID -ne 0 ]; then
    # failed
    ERRMSG="You are not root, You cannot execute this script."
    echo $ERRMSG 1>&2
    exit 100
fi

TMPDIR=/tmp/postgresql-backup.$$
mkdir -p $TMPDIR

trap "exit 1" HUP INT PIPE QUIT TERM
trap "rm -f ${TMPDIR}/*.dump; rmdir ${TMPDIR}; rm -f ${LOCKFILE}" EXIT

DATABASES=`
    psql \
        --host=${POSTGRESQLHOST} \
        --user=${POSTGRESQLUSER} \
        --list \
        --tuples-only \
        --pset="format=unaligned" \
        --pset="fieldsep=," \
    | sed 's!^postgres=CTc/postgres$!!g' \
    | cut --delimiter=',' --fields=1 \
    | sed 's/^template[01]$//g' \
    | sed '/^$/d'
`
if [ $? -ne 0 ]; then
    # failed
    ERRMSG="Failed to listup the databases on the PostgreSQL server."
    echo $ERRMSG 1>&2
    exit 200
fi

TODAY=`date +%Y%m%d`
DAY=`date +%d`

if [[ $DAY = $ALL_DUMP_DAY1 || $DAY = $ALL_DUMP_DAY2 ]]; then
BACKUP=${TMPDIR}/all-databases.${TODAY}.dump
pg_dumpall \
    --host=${POSTGRESQLHOST} \
    --username=${POSTGRESQLUSER} \
    | gzip -9 > $BACKUP
if [ $? -eq 0 ]; then
#    echo "Successful in the preparation of the all databases backup."
:
else
    ERRMSG="Failed in the preparation of the all databases backup."
    echo $ERRMSG 1>&2
    exit 201
fi

else
for DBNAME in $DATABASES
do
    BACKUP=${TMPDIR}/${DBNAME}.${TODAY}.dump
    pg_dump \
        --host=${POSTGRESQLHOST} \
        --username=${POSTGRESQLUSER} \
        --format=custom \
        $DBNAME > $BACKUP
    if [ $? -eq 0 ]; then
#        echo "Successful in the preparation of the database backup: ${DBNAME}"
:
    else
        # warning
        $ERRMSG "Failed in the preparation of the database backup: ${DBNAME}"
        echo $ERRMSG 1>&2
    fi
done

if [ ! -d $BACKUPDIR ]; then
    # failed
    ERRMSG="Datastore of backup does not exist: ${BACKUPDIR}"
    echo $ERRMSG 1>&2
    exit 202
fi
fi

[[ $DAY = $ALL_DUMP_DAY1 || $DAY = $ALL_DUMP_DAY2 ]] && BK_DAYS=30 || BK_DAYS=7
[[ $DAY = $ALL_DUMP_DAY1 || $DAY = $ALL_DUMP_DAY2 ]] && DEL_FILE="all-*[0-9]\{8\}.dump" || DEL_FILE="[0-9]\{8\}.dump"

find ${BACKUPDIR} -name $DEL_FILE -type f -mtime +${BK_DAYS} -exec rm {} \;

mv ${TMPDIR}/*.dump ${BACKUPDIR}/

#echo "Backup of the database on PostgreSQL server was completed."

# log write
`SetLOG_FOOTER "postgres dump end"`

exit 0