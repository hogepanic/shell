#!/bin/sh

BASE=$HOME
export LANG=en_US.UTF-8

# date
DATE=`date '+%Y%m%d'`

# sh setting
HTTP_LOG_DIR=/[contents log path]/log # 変更箇所
ANA_DIR=/[contents result path]/ana # 変更箇所
ANA_SRV_LIST=$ANA_DIR/servers.lst
ANA_FILES_LIST=$ANA_DIR/ana_files_list.dat
ANA_RETO_PATH=$BASE/htdocs/summary # 変更箇所
ANA_RETO=$ANA_RETO_PATH
MODE=''
PERL_CMD="$(which perl)"
PRINTF_CMD="$(which printf)"
CAT_CMD="$(which cat)"

# log setting
LOG_PATH=$ANA_DIR
LOG_FILE=log_ana.log
LOG_FILE_PATH="${LOG_PATH}/${LOG_FILE}"
LOG_TMP_PATH="/tmp/ana_httpd"
ANA_LIST_PATH=$LOG_TMP_PATH/ana_access_log.dat

# STATUS
EXIT_CD=0
HITS_CNT=0
CP_STATUS=0



###########################
#
# function
#
###########################

SetLOG_HEADER()
{
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

  LOG_DATE=`date '+%Y-%m-%d'`
  LOG_TIME=`date '+%H:%M:%S'`

  printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}" >>${LOG_PATH}
}

SetLOG_FOOTER()
{
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

  LOG_DATE=`date '+%Y-%m-%d'`
  LOG_TIME=`date '+%H:%M:%S'`

  printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}" >>${LOG_PATH}
}


#----------------------
#
# analytics
#
#----------------------

DoAna()
{

# cat log
($PERL_CMD $ANA_DIR/cat_access_log.pl ${LOG_TMP_PATH}/${LOGFILE}$MODE || echo $? >$STATUS_FILE) |sed '/^ *$/d' |sed '/^-$/d' 1>${ANA_LIST_PATH} 2>>${LOG_FILE_PATH}


### total uu per day

# report folder
UU_PATH=${ANA_RETO_PATH}/uu
mkdir -p ${UU_PATH} > /dev/null 2>&1

PV_FILE=${UU_PATH}/${YYYYMM}.csv$MODE

# log write date
LOG_DATE=`date --date "$TRANS_DATE day ago" +%Y/%m/%d` 

UU_CNT=`(cat ${ANA_LIST_PATH} 2>>${LOG_FILE_PATH} || echo $? >$STATUS_FILE) |awk '{print $4}' |sort|uniq -c|wc -l`

# write log
echo "$DATE,$UU_CNT" >> ${PV_FILE}


### total pv per day


# report folder
PV_PATH=${ANA_RETO_PATH}/pv/${YYYYMM}
mkdir -p ${PV_PATH} > /dev/null 2>&1

PV_FILE=${ANA_RETO_PATH}/pv/${YYYYMM}/$DAY.csv$MODE

# log write date
LOG_DATE=`date --date "$TRANS_DATE day ago" +%Y/%m/%d` 
echo $LOG_DATE > ${PV_FILE}


# times per loop
TIMES=0

while [ $TIMES -le 23 ]
do
  PV_PER_TIME=""
  TIMES=`$PRINTF_CMD "%02d\n" $TIMES`

  while read FILES
  do

    PV_PER_TIME=$PV_PER_TIME,`(less ${ANA_LIST_PATH} 2>>${LOG_FILE_PATH} || echo $? >$STATUS_FILE) | egrep "^($LOG_DATE $TIMES)" | cut -f 2 | egrep "^($FILES)" | wc -l`

  done <${ANA_FILES_LIST}

#  UU_PER_TIME=`(less ${ANA_LIST_PATH} 2>>${LOG_FILE_PATH} || echo $? >$STATUS_FILE) | egrep "^($LOG_DATE $TIMES)" | cut -f 3 |sort|uniq -c|wc -l`
    
  # write log
  echo "$TIMES:00$PV_PER_TIME" >> ${PV_FILE}
    
  TIMES=`expr $TIMES + 1`

done

}



###########################
#
# main
#
###########################

# check args
if [ $# -ne 0 ]; then
  MODE='.static'
fi

# report folder
mkdir -p ${ANA_RETO_PATH} > /dev/null 2>&1

# log write
`SetLOG_HEADER "log analytics start$MODE: " ${LOG_FILE_PATH}`

if [ ! -f $ANA_SRV_LIST ]; then
 echo "servers.lst not found" >> ${LOG_FILE_PATH}
 exit 1
fi

if [ ! -f $ANA_FILES_LIST ]; then
 echo "ana_files_list.dat not found" >> ${LOG_FILE_PATH}
 exit 1
fi

TRANS_DATE=$1
TRANS_DATE=${TRANS_DATE:=1}

# trans date
DATE=`date --date "$TRANS_DATE day ago" +%Y%m%d`
YYYYMM=`date --date "$TRANS_DATE day ago" +%Y%m`
DAY=`date --date "$TRANS_DATE day ago" +%d`
LOGFILE=access_$DATE.log
#LOGFILE=access_20101004.log


#----------------------
#
# log copy
#
#----------------------

# httpd log tmp folder
mkdir -p ${LOG_TMP_PATH} > /dev/null 2>&1

# local log copy
#cp ${HTTP_LOG_DIR}/${LOGFILE} ${LOG_TMP_PATH}/${DATE}_${LOGFILE}.$MODE 2>>${LOG_FILE_PATH} || CP_STATUS=1

cat $ANA_SRV_LIST | while read i;do
 if [ -n "$i" -a "${i:0:1}" != "#" ]; then

   # remote log copy 変更箇所
   scp $i:${HTTP_LOG_DIR}/${LOGFILE} ${LOG_TMP_PATH}/${DATE}_${i}_${LOGFILE}.$MODE 1>/dev/null 2>>${LOG_FILE_PATH} || CP_STATUS=1

 fi
done

# log merge
if [ ${CP_STATUS} -eq 0 ]; then
  cd ${LOG_TMP_PATH}
  $CAT_CMD `(ls -tr ${LOG_TMP_PATH} |grep ^${DATE} 2>>${LOG_FILE_PATH} || echo $? >$CP_STATUS)` > ${LOG_TMP_PATH}/${LOGFILE}$MODE 2>>${LOG_FILE_PATH} || CP_STATUS=1
fi

# check error
[ ${CP_STATUS} -eq 0 ] || exit 1


#----------------------
#
# main-continue
#
#----------------------

STATUS_FILE=/tmp/ana_status.$$
echo 0 >$STATUS_FILE

# do analytics
DoAna

# copy log file delete
rm -f ${LOG_TMP_PATH}/* 2>>${LOG_FILE_PATH} || STATUS_FILE=1

STATUS=`cat $STATUS_FILE`
rm -f $STATUS_FILE

# log write
if [ ${STATUS} -eq 0 -a ${CP_STATUS} -eq 0 ]; then
  `SetLOG_FOOTER "log analytics complete$MODE: " ${LOG_FILE_PATH}`
else
  `SetLOG_FOOTER "log analytics failed$MODE: " ${LOG_FILE_PATH}`
fi

# check error
if [ ${STATUS} -ne 0 ]; then
  exit 1
fi

exit $EXIT_CD