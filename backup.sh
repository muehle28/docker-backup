#!/bin/bash

BACKUP_DIR=/backups

mkdir -p -- "${BACKUP_DIR}"

case "${TYPE}" in
    
    ###################################
    ## MySQL
    ###################################
    "mysql")
	: ${PORT:=3306}
	mysqldump  --user${USER} --password${PASSWD} --host ${HOST} --port ${PORT} --databases ${DATABASES} > ${BACKUP_DIR}/database.sql
	;;

	###################################
    ## MongoDB
    ###################################
	"mongodb")
	: ${PORT:=37017}
	mongodump --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --out ${BACKUP_DIR}/database
	;;

esac
