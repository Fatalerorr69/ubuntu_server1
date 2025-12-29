#!/usr/bin/env bash
apt install -y cloud-init qemu-guest-agent

systemctl enable qemu-guest-agent
cloud-init clean
truncate -s 0 /etc/machine-id
