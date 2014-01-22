#!/bin/bash

# --共通関数定義--

#----------------
# ログ出力関数
#----------------

# ログヘッダ書き込み
# MSG：エラーメッセージ
# LOG_PATH：ログパス
SetLOG_HEADER()
{
  # 引数展開
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

  # 変数定義
  LOG_DATE=`GetYMD2`  # 年月日取得
  LOG_TIME=`GetTIME1` # 時刻取得

  # ログ出力実行
  printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}" >>${LOG_PATH}
}

# ログ詳細書き込み
# MSG：エラーメッセージ
# LOG_PATH：ログパス
SetLOG_DETAILS()
{
  # 引数展開
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

  # 変数定義
  LOG_DATE=`GetYMD2`  # 年月日取得
  LOG_TIME=`GetTIME1` # 時刻取得

  # ログ出力実行
  printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}" >>${LOG_PATH}
}

# ログフッター書き込み
# MSG：エラーメッセージ
# LOG_PATH：ログパス
SetLOG_FOOTER()
{
  # 引数展開
  FILENM=`basename $0`
  MSG=$1
  LOG_PATH=$2

  # 変数定義
  LOG_DATE=`GetYMD2`  # 年月日取得
  LOG_TIME=`GetTIME1` # 時刻取得

  # ログ出力実行
  printf "%-10s %-8s %-14s %-50s\n" \
   "${LOG_DATE}" "${LOG_TIME}" "${FILENM}" "${MSG}" >>${LOG_PATH}
}

#----------------
# システム関数
#----------------

# 年月日取得関数①
GetYMD1()
{
  SYSTEM_DATE=`date '+%Y%m%d'`
  echo ${SYSTEM_DATE}
}

# 年月日取得関数②
GetYMD2()
{
  SYSTEM_DATE=`date '+%Y-%m-%d'`
  echo ${SYSTEM_DATE}
}

# 年月日取得関数③
GetYMD3()
{
  SYSTEM_DATE=`date '+%Y/%m/%d'`
  echo ${SYSTEM_DATE}
}

# 年月取得関数①
GetYM1()
{
  SYSTEM_MONTH=`date '+%Y%m'`
  echo ${SYSTEM_MONTH}
}

# 時刻取得関数①
GetTIME1()
{
  SYSTEM_TIME=`date '+%H:%M:%S'`
  echo ${SYSTEM_TIME}
}

# 曜日取得関数
GetWEEK()
{
  SYSTEM_WEEK=`date +%a`
  echo ${SYSTEM_WEEK}
}

# 曜日取得関数
GetWEEK()
{
  SYSTEM_WEEK=`date +%a`
  echo ${SYSTEM_WEEK}
}

# 絶対パスからファイル名だけを取り出す
# $1：絶対パス
# $2：拡張子
GetFILENAME_BY_PATH()
{
  echo `basename $1 $2`
}

# プロセス監視&起動
# $1：起動確認プロセス
ChkPROC_SHELL()
{
  PROC_NAME=$1
  isAlive=`ps -ef | grep "${PROC_NAME}" | \
    grep -v grep | wc -l`
  if [ $isAlive = 1 ]; then
     isAlive=1
  else
    isAlive=0
  fi
  echo $isAlive
}


#----------------
# ディレクトリ関数
#----------------


# ディレクトリ作成
# DIR_PATH：作成パス
Create_DIR()
{
  DIR_PATH=$1
  mkdir -p ${DIR_PATH}
}

# ディレクトリ移動
# CD_PATH：移動パス
# MSG：エラーメッセージ
Dir_CD()
{
  CD_PATH=$1
  MSG=$2

  cd ${CD_PATH}
  if [ $? != 0 ]; then
   echo "${MSG} directory does not exist."
   exit 1
  fi
}

# フォルダ圧縮
# BK_PATH：圧縮先パス
# FILENAME：バックアップファイル名
# ORG_PATH：圧縮元パス
Dir_TAR()
{
  BK_PATH=$1
  FILENAME=$2
  ORG_PATH=$3
  # "tar:Removing leading '/' from member names"
  cd ${ORG_PATH}
  tar cvzf ${BK_PATH}${FILENAME} ./
}

# フォルダ削除
# DIR_PATH：ファイルパス
Dir_RM()
{
  DIR_PATH=$1
  rm -rf ${DIR_PATH}
}


#----------------
# ファイル関数
#----------------


# ファイルコピー
# ORG_DIR_PATH：コピー元ファイルパス
# ORG_FILENAME：ファイル名
# SAKI_DIR_PATH：コピー先パス
# SAKI_FILENAME：コピーファイル
File_CP()
{
  ORG_DIR_PATH=$1
  ORG_FILENAME=$2
  SAKI_DIR_PATH=$3
  SAKI_FILENAME=$4

  cp ${ORG_DIR_PATH}${ORG_FILENAME} ${SAKI_DIR_PATH}${SAKI_FILENAME}
}

# ファイル削除
# DIR_PATH：ファイルパス
# FILENAME：ファイル名
File_RM()
{
  DIR_PATH=$1
  FILENAME=$2

  rm -f ${DIR_PATH}${FILENAME}
}

# ファイル削除処理関数 (分数)
# 更新時刻からn分経過した指定ファイル形式のファイルを削除
# FILE_FORMAT：ファイルフォーマット
# BK_DIR：バックアップパス
# BK_DAYS：保持する分数
DelFILE_BY_MIN_ONUPTIME()
{
  FILE_FORMAT=$1
  BK_DIR=$2
  BK_DAYS=$3
  find ${BK_DIR} -name "${FILE_FORMAT}" -type f -mmin +${BK_DAYS} -exec rm {} \;
}

# ファイル削除処理関数 (日数)
# 更新時刻からn日経過した指定ファイル形式のファイルを削除
# FILE_FORMAT：ファイルフォーマット
# BK_DIR：バックアップパス
# BK_DAYS：保持する日数
DelFILE_BY_DAY_ONUPTIME()
{
  FILE_FORMAT=$1
  BK_DIR=$2
  BK_DAYS=$3
  find ${BK_DIR} -name "${FILE_FORMAT}" -type f -mtime +${BK_DAYS} -exec rm {} \;
}

# 外部ファイル読み込み
# FILE_PATH:外部ファイルパス
# 戻り値：配列
Read_OUTSIDE_FILE()
{
  FILE_PATH=$1
  # read コマンドで読み取れなくなるまでループ
  count=0

  while read LINE
  do
    #echo "$LINE"
    # 配列作成
    ARRAY[$count]=$LINE
    # カウント加算
    count=`expr $count+1`
  done < ${FILE_PATH}

  echo ${ARRAY[@]}
}



#----------------
# 文字列関数
#----------------


# 文字列置換
# TARGET：対象文字列
# SEARCH_STR：検索文字列
# REPLACE_STR：置換文字列
Do_REPLACE_STR()
{
  TARGET=$1
  SEARCH_STR=$2
  REPLACE_STR=$3

  TARGET_FILE=`echo ${TARGET} | sed -e "s/${SEARCH_STR}/${REPLACE_STR}/"`

  echo ${TARGET_FILE}
}

# 変数存在チェック関数
# 変数が未設定の場合、代替変数に置き換える
# TARGET：対象文字列
# REPLACE_STR：置換文字列
Do_REPLACE_EMPTY()
{
  TARGET=$1
  REPLACE_STR=$2
  echo ${TARGET:-${REPLACE_STR}}
}

# 任意文字列存在チェック関数
# TARGET：対象文字列
# SEARCH_STR：検索文字列
Do_GREP_STR()
{
  TARGET=$1
  SEARCH_STR=$2
  echo `grep "${SEARCH_STR}" ${TARGET}`
}


#----------------
# メール関数
#----------------

# メール送信関数
# TOADDRESS：送信アドレス
# SUBJECT：件名
# MSG：内容
Do_SENDMAIL(){
  TOADDRESS=$1
  SUBJECT=$2
  MSG=$3

  echo -e "${MSG}" | mail -s "${SUBJECT}" "${TOADDRESS}"
}