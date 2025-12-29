#!/usr/bin/env bash

cat <<EOF > /etc/systemd/system/core-webui.service
[Unit]
Description=Core Web UI
After=network.target

[Service]
User=coreadmin
WorkingDirectory=/srv/webui
ExecStart=/srv/webui/venv/bin/uvicorn app:app --host 127.0.0.1 --port 9000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable core-webui --now
