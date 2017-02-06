#!/bin/bash
set -e

mkdir -p -- ${HOME}/.ssh
cat << EOF > ${HOME}/.ssh/config
Host *
    StrictHostKeyChecking no
EOF

BACKUP_DIR=/backups

cat << EOF > /etc/cron.d/backup
${CRON//\"/} root . /root/backup_env.sh; /backup.sh > /var/log/backup

EOF

chmod 0644 /etc/cron.d/backup

printenv | sed 's/^\(.*\)$/export \1/g' > /root/backup_env.sh
chmod +x /root/backup_env.sh

mkdir -p -- "${BACKUP_DIR}"

#Mount remote filesystem
case "${REMOTE_TYPE}" in
	###################################
    ## Webdav
    ###################################
	"webdav")
	echo "Mounting WebDAV: ${REMOTE_HOST}"
	echo "${REMOTE_HOST} ${REMOTE_USER} ${REMOTE_PASSWD}">/etc/davfs2/secrets
	mount -t davfs ${REMOTE_HOST} ${BACKUP_DIR}
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
	   echo "Waiting for mysql ..."
	   sleep 3
	done
	echo "Mysql server ready."
	tables=`mysql --user ${USER} --password=${PASSWD} --host ${HOST} --port ${PORT} -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"${DATABASE}\";"`
	echo "Tables found: $tables"
	if [ $tables -eq 0 ]; then
		echo "${TYPE} Database is empty. Restore last backup."
		/backup.sh restore latest
	fi
	;;

	###################################
    ## MongoDB
    ###################################
	"mongodb")
	echo "Init ${TYPE} database ..."
	: ${PORT:=37017}
	;;

esac

echo "Starting cron..."
exec "$@"
