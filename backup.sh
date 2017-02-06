#!/bin/bash

BACKUP_DIR=/backups/${TYPE}
BACKUP_FILENAME=`date +"%s"`

mkdir -p -- "${BACKUP_DIR}"

function getLatestBackupFilename(){
	ls ${BACKUP_DIR} | sed 's/\([0-9]\+\).*/\1/g' | sort -n | tail -1
}

if [ $# -eq 0 ]; then

	echo "Staring ${TYPE} backup..."
	case "${TYPE}" in
	    
	    ###################################
	    ## MySQL
	    ###################################
	    "mysql")
		: ${PORT:=3306}
		mysqldump --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} --databases ${DATABASE} --single-transaction --routines --triggers > ${BACKUP_DIR}/${BACKUP_FILENAME}
		;;

		###################################
	    ## MongoDB
	    ###################################
		"mongodb")
		: ${PORT:=37017}
		mongodump --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --out ${BACKUP_DIR}/${BACKUP_FILENAME}
		;;

	esac
	echo "Backup ${TYPE} completed..."

else
	if [ ! $1 = "restore" ]; then
		echo "Wrong argument."
		exit 1
	fi
	echo "Staring ${TYPE} restore..."
	if [ -z $2 ] || [ $2 = "latest" ]; then
		RESTORE_FILENAME=`getLatestBackupFilename`
	else
		RESTORE_FILENAME=$2
	fi
	if [ ! -f ${BACKUP_DIR}/${RESTORE_FILENAME} ]; then
	    echo "Backupfile not found: ${BACKUP_DIR}/${RESTORE_FILENAME}"
	    exit 1
	fi
	echo "Start restoring backup: ${BACKUP_DIR}/${RESTORE_FILENAME}"
	case "${TYPE}" in
	    
	    ###################################
	    ## MySQL
	    ###################################
	    "mysql")
		: ${PORT:=3306}
		mysql --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} ${DATABASE} < ${BACKUP_DIR}/${RESTORE_FILENAME}
		;;

		###################################
	    ## MongoDB
	    ###################################
		"mongodb")
		: ${PORT:=37017}
		mongorestore --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} ${BACKUP_DIR}/${RESTORE_FILENAME}
		;;

	esac

fi
