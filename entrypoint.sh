#!/bin/bash
set -e

DATA_BACKUP_DIR=/databackup
BACKUP_DIR=/backups

mkdir -p ${BACKUP_DIR}
mkdir -p ${DATA_BACKUP_DIR}

mkdir -p ${HOME}/.ssh
cat << EOF > ${HOME}/.ssh/config
Host *
    StrictHostKeyChecking no
EOF

cat << EOF > /etc/cron.d/backup
${CRON//\"/} root . /root/backup_env.sh; /backup.sh > /var/log/backup

EOF

chmod 0644 /etc/cron.d/backup

printenv | sed 's/^\(.*\)$/export \1/g' > /root/backup_env.sh
chmod +x /root/backup_env.sh

#Mount remote filesystem
case "${REMOTE_TYPE}" in
	###################################
    ## Webdav
    ###################################
	"webdav")
	echo "Mounting WebDAV: ${REMOTE_HOST}"
	echo "${REMOTE_HOST} ${REMOTE_USER} ${REMOTE_PASSWD}">/etc/davfs2/secrets
	mount -t davfs https://${REMOTE_HOST} ${BACKUP_DIR}
	;;

	###################################
    ## SSHFS
    ###################################
	"sshfs")
	echo "Mounting SSHFS: ${FTP_URL}"
	echo ${REMOTE_PASSWD} | sshfs -o password_stdin -o reconnect -o ServerAliveInterval=15 ${REMOTE_USER}@${REMOTE_HOST}:/ ${BACKUP_DIR}
	;;
esac

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
	while !(mongo --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --authenticationDatabase ${DATABASE} --authenticationMechanism SCRAM-SHA-1 --eval "db.stats()" ${DATABASE}) do
    	echo "Waiting for ${TYPE} ..."
		sleep 3
	done;
	set -e
	echo "Mongodb server is ready."
	tables=$(mongo --username ${USER} --password ${PASSWD} --host ${HOST} --port ${PORT} --authenticationDatabase ${DATABASE} --authenticationMechanism SCRAM-SHA-1 --eval "db.stats()" ${DATABASE} | grep -Po '"collections"\s:\s\K[0-9]+')
	if [ $tables -eq 0 ]; then
		echo "${TYPE} Database is empty. Restoring latest backup."
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
