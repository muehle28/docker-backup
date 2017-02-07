#!/bin/bash
: ${REMOTE_DIR:=backup}
: ${REMOTE_GENERATIONS:=30}
BACKUP_DIR=/backups/${REMOTE_DIR}/${TYPE}
BACKUP_FILENAME=`date +"%s"`
#ATTENTION!! If you do a restore the content of this folder will be replaced.  
DATA_BACKUP_DIR=/databackup

mkdir -p ${BACKUP_DIR}
mkdir -p ${DATA_BACKUP_DIR}

function getLatestBackupFilename(){
	ls ${BACKUP_DIR} | sed 's/\([0-9]\+\).*/\1/g' | sort -n | tail -1
}

function getOldestBackupFilename(){
	ls ${BACKUP_DIR} | sed 's/\([0-9]\+\).*/\1/g' | sort -n -r | tail -1
}

function checkGenerations(){
	echo "Checking for generations"
	((count=`ls -l ${BACKUP_DIR} | grep -v ^d | wc -l` - 1))
	if [ $count -gt ${REMOTE_GENERATIONS} ]; then
		filename=`getOldestBackupFilename`
		
		if [ ! -f ${BACKUP_DIR}/${filename} ]; then
	    	echo "Backupfile not found: ${BACKUP_DIR}/${filename}"
	    	exit 1
		fi
		rm ${BACKUP_DIR}/${filename}
		checkGenerations
	fi
}

if [ $# -eq 0 ]; then

	echo "Staring ${TYPE} backup..."
	case "${TYPE}" in
	    
	    ###################################
	    ## MySQL
	    ###################################
	    "mysql")
		: ${PORT:=3306}
		mysqldump --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} --databases ${DATABASE} --add-drop-database --single-transaction --routines --triggers | gzip > ${BACKUP_DIR}/${BACKUP_FILENAME}
		;;

		###################################
	    ## MongoDB
	    ###################################
		"mongodb")
		: ${PORT:=27017}
		mongodump --username=${USER} --password=${PASSWD} --host=${HOST} --port=${PORT} --db=${DATABASE} --archive=${BACKUP_DIR}/${BACKUP_FILENAME} --gzip
		;;

		###################################
	    ## Data
	    ###################################
		"data")
		tar -zcf ${BACKUP_DIR}/${BACKUP_FILENAME} -C ${DATA_BACKUP_DIR} .
		;;

	esac
	echo "Backup ${TYPE} completed..."
	checkGenerations

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
		gunzip < ${BACKUP_DIR}/${RESTORE_FILENAME} | mysql --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} ${DATABASE}
		;;

		###################################
	    ## MongoDB
	    ###################################
		"mongodb")
		: ${PORT:=27017}
		mongorestore --username=${USER} --password=${PASSWD} --host=${HOST} --port=${PORT} --authenticationDatabase=${DATABASE} --drop --archive=${BACKUP_DIR}/${RESTORE_FILENAME} --gzip
		;;

		###################################
	    ## Data
	    ###################################
		"data")
		cd ${DATA_BACKUP_DIR} && rm -rf ..?* .[!.]* *
		tar -zxf ${BACKUP_DIR}/${RESTORE_FILENAME} -C ${DATA_BACKUP_DIR}
		;;

	esac

fi
