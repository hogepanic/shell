#!/bin/sh

DIRS='/[contents path]/log'

GTAR="/bin/tar czf"
PRINTF_CMD="$(which printf)"
LOGGER="$(which logger)"
LOGGER_CMD="${LOGGER} -p cron.info"
GZIP="/usr/bin/gzip -f"
#BK_DAYS=14

##########################
#
# function
#
##########################

SetLOG_HEADER()
{
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

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
  LOG_PATH=$2

  LOG_DATE=`date '+%Y-%m-%d'`
  LOG_TIME=`date '+%H:%M:%S'`

  STR=$(printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}")

  ${LOGGER_CMD} ${STR}
}


##### MAIN ######

# log write
`SetLOG_HEADER "log comp start"`


# dir check
SDIR=`date --date "1 day ago" +%Y%m%d`


# compression

DIR_DST="/[contents path]/[dst]"
cd ${DIR_DST}
${LOGGER_CMD} ${SDIR}
mv ${DIRS}/access.log ${SDIR}_access.log && mv ${DIRS}/error.log ${SDIR}_error.log
${GZIP} ${SDIR}_access.log && ${GZIP} ${SDIR}_error.log

  if [ $? -eq 0 ]; then
   :
  else
   echo  "tar can not"
   exit 1
  fi

# log write
`SetLOG_FOOTER "log comp end"`

exit 0
