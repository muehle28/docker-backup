#!/bin/bash
set -e

cat << EOF >> /etc/cron.d/soop-cron
${CRON} root /backup.sh\n
EOF

echo "Starting crontab..."

exec "$@"
