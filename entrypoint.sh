#!/bin/bash
set -e

cat << EOF >> /etc/cron.d/backupjob
${CRON} root /backup.sh

EOF

chmod 0644 /etc/cron.d/backupjob

echo "Starting cron..."

exec "$@"
