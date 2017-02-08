#!/bin/sh
set -e

DATA_BACKUP_DIR=/databackup
BACKUP_DIR=/backups

mkdir -p ${BACKUP_DIR}
mkdir -p ${DATA_BACKUP_DIR}

cat << EOF > /var/spool/cron/crontabs/backup
${CRON//\"/} . /root/backup_env.sh; /backup.sh > /var/log/backup

EOF

chmod 0644 /var/spool/cron/crontabs/backup
/usr/bin/crontab /var/spool/cron/crontabs/backup

printenv | sed 's/^\(.*\)$/export \1/g' > /root/backup_env.sh
chmod +x /root/backup_env.sh

#Init database
case "${TYPE}" in
    
    ###################################
    ## MySQL
    ###################################
    "mysql")
	echo "Init ${TYPE} database ..."
	: ${PORT:=3306}
	while !(mysqladmin --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} ping > /dev/null 2>&1)
	do
	   echo "Waiting for ${TYPE} ..."
	   sleep 3
	done
	echo "Mysql server is ready."
	tables=`mysql --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"${DATABASE}\";"`
	echo "Tables found: $tables"
	if [ $tables -eq 0 ]; then
		echo "${TYPE} Database is empty. Restoring latest backup."
		set +e
		/backup.sh restore latest
		set -e
	fi
	;;

	###################################
    ## MongoDB
    ###################################
	"mongodb")
	echo "Init ${TYPE} database ..."
	: ${PORT:=27017}
	set +e
	while !(mongo --username=${USER} --password=${PASSWD} --host=${HOST} --port=${PORT} --authenticationDatabase=${DATABASE} --eval "db.stats()" ${DATABASE}) do
    	echo "Waiting for ${TYPE} ..."
		sleep 3
	done;
	set -e
	echo "Mongodb server is ready."
	tables=$(echo $(mongo --username=${USER} --password=${PASSWD} --host=${HOST} --port=${PORT} --authenticationDatabase=${DATABASE} --eval "db.stats()" ${DATABASE}) | sed -e 's/[^{]* //' | jq -r '.collections')
	if [ $tables -eq 0 ]; then
		echo "${TYPE} Database is empty. Restoring latest backup."
		sleep 3
		set +e
		/backup.sh restore latest
		set -e
	fi
	;;

	###################################
    ## Data
    ###################################
	"data")
	echo "Init ${TYPE} directory ..."
	if [ ! "$(ls -A /databackup)" ]; then
		echo "${TYPE} directory is empty. Restoring latest backup."
		set +e
		/backup.sh restore latest
		set -e
	fi
	;;

esac

echo "Starting cron..."
exec "$@"
