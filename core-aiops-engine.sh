#!/usr/bin/env bash

OUT="/srv/aiops/state.json"

cat <<EOF > $OUT
{
  "cpu": "$(uptime)",
  "disk": "$(df -h / | tail -1)",
  "services_failed": "$(systemctl --failed | wc -l)",
  "last_logs": "$(journalctl -p 3 -n 10 | tail -n 10)"
}
EOF
