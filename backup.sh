#!/bin/bash

BACKUP_DIR=/backups

mkdir -p -- "${BACKUP_DIR}"

timestamp() {
  date +"%s"
}

echo "Staring ${TYPE} backup..."
case "${TYPE}" in
    
    ###################################
    ## MySQL
    ###################################
    "mysql")
	: ${PORT:=3306}
	mysqldump  --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} --databases ${DATABASES} --single-transaction --routines --triggers > ${BACKUP_DIR}/${TYPE}.`timestamp`.sql
	;;

	###################################
    ## MongoDB
    ###################################
	"mongodb")
	: ${PORT:=37017}
	mongodump --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --out ${BACKUP_DIR}/${TYPE}.`timestamp`
	;;

esac
echo "Backup ${TYPE} completed..."
