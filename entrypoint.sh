#!/bin/bash
set -e

cat << EOF >> /etc/cron.d/backup
${CRON} root . /root/backup_env.sh; /backup.sh > /var/log/backup

EOF

chmod 0644 /etc/cron.d/backup

printenv | sed 's/^\(.*\)$/export \1/g' > /root/backup_env.sh
chmod +x /root/backup_env.sh

echo "Starting cron..."

rsyslogd
exec "$@"
