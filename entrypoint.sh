#!/bin/bash
set -e

cat << EOF >> /etc/cron.d/soop-cron
${CRON} /backup.sh

EOF

echo "Starting crontab..."

exec "$@"
