#!/usr/bin/env bash

cat <<EOF > /srv/aiops/context.txt
Hostname: $(hostname)
Uptime: $(uptime)
Disk: $(df -h / | tail -1)
Failed services:
$(systemctl --failed)
EOF
