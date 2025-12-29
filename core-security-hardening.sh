#!/usr/bin/env bash
set -e

# Kernel
cat <<EOF >> /etc/sysctl.conf
kernel.randomize_va_space=2
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
EOF

sysctl -p

# Disable unused FS
echo "install cramfs /bin/false" >> /etc/modprobe.d/hardening.conf
echo "install squashfs /bin/false" >> /etc/modprobe.d/hardening.conf
