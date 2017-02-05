#!/bin/bash

BACKUP_DIR=/backups/${TYPE}
FILENAME=${TYPE}.`date +"%s"`

mkdir -p -- "${BACKUP_DIR}"

echo "Staring ${TYPE} backup..."
case "${TYPE}" in
    
    ###################################
    ## MySQL
    ###################################
    "mysql")
	: ${PORT:=3306}
	mysqldump  --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} --databases ${DATABASES} --single-transaction --routines --triggers > ${BACKUP_DIR}/${FILENAME}
	;;

	###################################
    ## MongoDB
    ###################################
	"mongodb")
	: ${PORT:=37017}
	mongodump --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --out ${BACKUP_DIR}/${FILENAME}
	;;

esac

if [ -n "${FTP_URL}" ]; then
	echo "Send file to ftp server: ${FTP_URL}"
	lftp -u ${FTP_USER},${FTP_PASS} -p 22 sftp://${FTP_HOST} <<EOF
cd ${BACKUP_DIR}"
put ${BACKUP_DIR}/${FILENAME}
bye
EOF

fi

echo "Backup ${TYPE} completed..."
