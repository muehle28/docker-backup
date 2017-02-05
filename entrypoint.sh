#!/bin/bash
set -e

cat << EOF >> /etc/cron.d/backup
${CRON} root /backup.sh > /var/log/backup

EOF

chmod 0644 /etc/cron.d/backup

echo "Starting cron..."

rsyslogd
exec "$@"
