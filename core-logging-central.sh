#!/usr/bin/env bash
set -e

apt install -y rsyslog logrotate

cat <<EOF >> /etc/rsyslog.conf
*.* /srv/logs/system.log
EOF

systemctl restart rsyslog
