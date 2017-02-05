#!/bin/bash
set -e
BACKUP_DIR=/backups

cat << EOF >> /etc/cron.d/backup
${CRON//\"/} root . /root/backup_env.sh; /backup.sh > /var/log/backup

EOF

chmod 0644 /etc/cron.d/backup

printenv | sed 's/^\(.*\)$/export \1/g' > /root/backup_env.sh
chmod +x /root/backup_env.sh

mkdir -p -- "${BACKUP_DIR}"
if [ -n "${WEBDAV_URL}" ]; then
	echo "Mounting WebDAV: ${WEBDAV_URL}"
	echo "${WEBDAV_URL} ${WEBDAV_USER} ${WEBDAV_PASSWD}">/etc/davfs2/secrets
	mount -t davfs ${WEBDAV_URL} /backup_ext
fi

echo "Starting cron..."

rsyslogd
exec "$@"
