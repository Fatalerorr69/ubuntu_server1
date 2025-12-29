#!/usr/bin/env bash
set -e

echo "[GUI] Aktualizuji systém…"
apt update && apt upgrade -y

echo "[GUI] Instalace XFCE4 a základních nástrojů…"
apt install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils

echo "[GUI] Instalace VNC serveru…"
apt install -y tigervnc-standalone-server tigervnc-common

echo "[GUI] Nastavení VNC pro uživatele coreadmin…"
su - coreadmin <<'EOF'
mkdir -p ~/.vnc
echo "password" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
EOF

echo "[GUI] Vytvoření systemd služby pro VNC…"
cat <<EOL > /etc/systemd/system/vncserver@:1.service
[Unit]
Description=VNC Server XFCE4
After=network.target

[Service]
Type=forking
User=coreadmin
PAMName=login
PIDFile=/home/coreadmin/.vnc/%H:1.pid
ExecStartPre=-/usr/bin/vncserver -kill :1
ExecStart=/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable vncserver@:1 --now

echo "[GUI] Instalace dokončena. Připojte se na VNC:1 (port 5901)"
