#!/usr/bin/env bash
NAME="$1"
[[ -z "$NAME" ]] && exit 1

wg genkey | tee /tmp/$NAME.key | wg pubkey > /tmp/$NAME.pub

cat <<EOF >> /etc/wireguard/wg0.conf
[Peer]
PublicKey = $(cat /tmp/$NAME.pub)
AllowedIPs = 10.77.0.$((RANDOM%200+20))/32
EOF

wg-quick down wg0 && wg-quick up wg0
