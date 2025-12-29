#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/var/log/core-wireguard.log"

apt update
apt install -y wireguard qrencode

WG_IF="wg0"
WG_NET="10.77.0.0/24"
SERVER_IP=$(hostname -I | awk '{print $1}')

umask 077
wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub

cat <<EOF > /etc/wireguard/$WG_IF.conf
[Interface]
Address = 10.77.0.1/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/server.key)
EOF

systemctl enable wg-quick@$WG_IF
systemctl start wg-quick@$WG_IF
