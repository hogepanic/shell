#!/bin/bash

cd /app_path/

. common.inc
. info_db.inc

export LANG=en_US.UTF-8
APNAME=`basename $1`
POINT_DB=$2
ROOT_PATH=/app_path/backup/ret/
PG_RET="${ROOT_PATH}pg_ret.log"


DATE=`GetYMD1`

BK_PATH=${ROOT_PATH}db/
BK_TMP=${ROOT_PATH}tmp/

LOG_PATH="${ROOT_PATH}log/"
LOG_FILE="${APNAME}-mysql-bk.log"
LOG_FILE_PATH="${LOG_PATH}${LOG_FILE}"

BK_DAYS=5

Dir_RM ${BK_TMP}
Create_DIR ${BK_PATH}
Create_DIR ${BK_TMP}
Create_DIR ${LOG_PATH}

SELECT_DB=`Do_REPLACE_EMPTY ${POINT_DB} "all"`

MAIL_CMD="$(which mail)"
MAILTO="youradress@test.jp"
MAILFROM="cron_mysql_bk@`hostname`"
MAIL_SUBJECT="cron_mysql_bk_report"

SEND_MAIL_FLG=0


###########################
#
# function
#
###########################

SEND_MAIL(){

MAIL_SUBJECT_SUB="__faild__"
EXIT_CD=1

$MAIL_CMD -s ${MAIL_SUBJECT}${MAIL_SUBJECT_SUB} ${MAILTO} -- -f ${MAILFROM} <<_EOF

${MAIL_SUBJECT}${MAIL_SUBJECT_SUB}
`date +"%Y-%m-%d %H:%M"`
err_code:$1

_EOF

}

###########################
#
# main
#
###########################

SetLOG_HEADER "backup start: " ${LOG_FILE_PATH}

LOG_FILE=`echo 'show slave status\G' | mysql  -u $DB_USER -h $DB_HOST -p$DB_PASS | egrep 'Relay_Master_Log_File:' | tr -d ' ' | cut -d ':' -f 2`
LOG_POS=`echo 'show slave status\G' | mysql  -u $DB_USER -h $DB_HOST -p$DB_PASS | egrep 'Read_Master_Log_Pos:' | tr -d ' ' | cut -d ':' -f 2`

if [ -z $LOG_FILE ]; then
#   echo "Log file name is empty."
   SetLOG_DETAILS "database -----> Log file name is empty.: " ${LOG_FILE_PATH}
   echo `SEND_MAIL ${STATUS}`
   exit 1
fi

if [ -z $LOG_POS ]; then
#   echo "Log position is empty."
   SetLOG_DETAILS "database -----> Log position is empty.: " ${LOG_FILE_PATH}
   echo `SEND_MAIL ${STATUS}`
   exit 1
fi

SetLOG_DETAILS "LOG_FILE -----> ${LOG_FILE}: " ${LOG_FILE_PATH}
SetLOG_DETAILS "LOG_POS -----> ${LOG_POS}: " ${LOG_FILE_PATH}


DUMP_FILE_NAME=${APNAME}_${DATE}.mydump

STATUS_FILE=/tmp/mysql_status.$$
echo 0 >$STATUS_FILE

DUMP_FILE_NAME_TAR=${DUMP_FILE_NAME}.tar.gz
($DB_SQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB_PARAM ${APNAME} 2>>${LOG_FILE_PATH} || echo $? >$STATUS_FILE) | gzip -9 > ${BK_PATH}${DUMP_FILE_NAME_TAR} 2>>${LOG_FILE_PATH}

MYSQL_STATUS=`cat $STATUS_FILE`
rm -f $STATUS_FILE

STATUS=$?
if [ ${STATUS} -ne 0 -o $MYSQL_STATUS -ne 0 ]; then
  SEND_MAIL_FLG=1
  SetLOG_DETAILS "dump gzip -----> `cat ${PG_RET}`: " ${LOG_FILE_PATH}
fi




if [ ${SEND_MAIL_FLG} -eq 1 ]; then
 echo `SEND_MAIL ${STATUS}`
fi

if [ ${SEND_MAIL_FLG} -eq 0 ]; then
  DelFILE_BY_DAY_ONUPTIME ${APNAME}_????????.mydump.tar.gz ${BK_PATH} ${BK_DAYS}
fi


if [ ${SEND_MAIL_FLG} -eq 1 ]; then
  echo `SEND_MAIL ${STATUS}`
  SetLOG_FOOTER "backup failed: " ${LOG_FILE_PATH}
else
  SetLOG_FOOTER "backup complete: " ${LOG_FILE_PATH}
fi