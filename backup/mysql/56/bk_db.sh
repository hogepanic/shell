#!/bin/bash

# --共通関数ファイル読込--
# ディレクトリ移動
cd /app_path/

source ./common.inc
source ./info_db.inc

# 基本設定
export LANG=en_US.UTF-8
APNAME=`basename $1`   
POINT_DB=$2  
ROOT_PATH=/root/backup/
PG_RET="${ROOT_PATH}pg_ret.log"


# 年月日取得関数
DATE=`GetYMD1`

# 曜日取得
WEEK=`GetWEEK`

# バックアップ先パス
BK_PATH=${ROOT_PATH}db/
BK_TMP=${ROOT_PATH}tmp/

# LOG設定
LOG_PATH="${ROOT_PATH}log/"
LOG_FILE="${APNAME}-mysql-bk.log"
LOG_FILE_PATH="${LOG_PATH}${LOG_FILE}"

# 保存する日数
BK_DAYS=30

# ディレクトリ削除・作成
Dir_RM ${BK_TMP}
Create_DIR ${BK_PATH}
Create_DIR ${BK_TMP}
Create_DIR ${LOG_PATH}

# 引数にDB名がセットされているか
SELECT_DB=`Do_REPLACE_EMPTY ${POINT_DB} "all"`

# mail setting
MAIL_CMD="$(which mail)"
MAILTO="youradress@test.jp"
MAILFROM="cron_mysql_bk@`hostname`"
MAIL_SUBJECT="cron_mysql_bk_report"

# メール送信フラグ
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

if [ ${WEEK} = Sun ]
then
  DUMP_FILE_NAME=${APNAME}_${DATE}.mydump
else
  DUMP_FILE_NAME=${APNAME}_${WEEK}_${SELECT_DB}.mydump
fi

if [ ${SELECT_DB} = all ]
then
 # 全てのDBを取得
 DBS="$($DB_TYPE -u $DB_USER -h $DB_HOST -p$DB_PASS -Bse 'show databases')"

 # databaseを１つずつdumpする
 for db in $DBS
 do
  FILE=${BK_TMP}mysql-${db}-${DUMP_FILE_NAME}
  $DB_SQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB_PARAM $db 1>${FILE} 2>>${LOG_FILE_PATH}

  # 終了ステータス
  STATUS=$?
  if [ ${STATUS} -ne 0 ]; then
    SetLOG_DETAILS "database -----> dump/error: $db " ${LOG_FILE_PATH}
    SEND_MAIL_FLG=1
  fi

 done
else
 # 指定DBを取得
 FILE=${BK_TMP}mysql-${SELECT_DB}-${DUMP_FILE_NAME}
 $DB_SQLDUMP -u $DB_USER -h $DB_HOST -p$DB_PASS $DB_PARAM ${SELECT_DB} 1>${FILE} 2>>${LOG_FILE_PATH}
fi

STATUS=$?
if [ ${STATUS} -ne 0 -o ${SEND_MAIL_FLG} -eq 1 ]; then
   SetLOG_DETAILS "database -----> dump/error: " ${LOG_FILE_PATH}
   echo `SEND_MAIL ${STATUS}`
   exit 1
fi

# フォルダ圧縮
DUMP_FILE_NAME_TAR=${DUMP_FILE_NAME}.tar.gz
Dir_TAR ${BK_PATH} ${DUMP_FILE_NAME_TAR} ${BK_TMP} > ${PG_RET} 2>&1

STATUS=$?
if [ ${STATUS} -ne 0 ]; then
  SEND_MAIL_FLG=1
  SetLOG_DETAILS "フォルダ圧縮 -----> `cat ${PG_RET}`: " ${LOG_FILE_PATH}
fi


if [ ${SEND_MAIL_FLG} -eq 1 ]; then
 echo `SEND_MAIL ${STATUS}`
fi

if [ ${SEND_MAIL_FLG} -eq 0 ]; then
  DelFILE_BY_DAY_ONUPTIME ${APNAME}_????????_${WEEK}_*.data.tar.gz ${BK_PATH} ${BK_DAYS}
fi

if [ ${SEND_MAIL_FLG} -eq 1 ]; then
  SetLOG_FOOTER "backup failed: " ${LOG_FILE_PATH}
else
  SetLOG_FOOTER "backup complete: " ${LOG_FILE_PATH}
fi