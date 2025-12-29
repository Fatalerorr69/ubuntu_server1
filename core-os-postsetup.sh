#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# CORE OS POST-SETUP
# Automatické doladění OS, softwaru a výkonu
###############################################################################

LOG_FILE="/var/log/core-os-postsetup.log"
ADMIN_USER="coreadmin"

log() {
  echo "[`date '+%F %T'`] $1" | tee -a "$LOG_FILE"
}

require_root() {
  [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
}

require_root
log "START POST-SETUP"

###############################################################################
# FÁZE A – ZÁKLADNÍ ADMIN SOFTWARE
###############################################################################
log "FÁZE A – Admin nástroje"

apt install -y \
  mc ncdu neofetch \
  tree jq fzf \
  iotop iftop \
  lm-sensors \
  bash-completion \
  fonts-dejavu fonts-firacode

###############################################################################
# FÁZE B – LOGGING & ROTACE
###############################################################################
log "FÁZE B – logrotate + journald"

sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
sed -i 's/^#RuntimeMaxUse=.*/RuntimeMaxUse=200M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

cat << 'EOF' > /etc/logrotate.d/core-custom
/var/log/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
}
EOF

###############################################################################
# FÁZE C – KERNEL & SYSCTL OPTIMALIZACE
###############################################################################
log "FÁZE C – sysctl tuning"

cat << 'EOF' > /etc/sysctl.d/99-core-tuning.conf
# Network
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.ip_forward = 1

# VM
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# FS
fs.inotify.max_user_watches = 524288
EOF

sysctl --system

###############################################################################
# FÁZE D – IO & SCHEDULER (VM SAFE)
###############################################################################
log "FÁZE D – IO scheduler"

for d in /sys/block/sd*; do
  echo mq-deadline > "$d/queue/scheduler" 2>/dev/null || true
done

###############################################################################
# FÁZE E – DESKTOP UX (XFCE)
###############################################################################
log "FÁZE E – XFCE optimalizace"

sudo -u "$ADMIN_USER" mkdir -p /home/$ADMIN_USER/.config/xfce4/xfconf/xfce-perchannel-xml

cat << 'EOF' > /home/$ADMIN_USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
EOF

chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.config

###############################################################################
# FÁZE F – SÍŤ & DNS
###############################################################################
log "FÁZE F – DNS & networking"

apt install -y resolvconf
echo "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

###############################################################################
# FÁZE G – MONITORING (NETDATA)
###############################################################################
log "FÁZE G – Netdata"

apt install -y netdata
systemctl enable --now netdata

###############################################################################
# FÁZE H – ČISTĚNÍ
###############################################################################
log "FÁZE H – cleanup"

apt autoremove -y
apt autoclean -y

###############################################################################
# FINÁLE
###############################################################################
log "POST-SETUP DOKONČEN"
log "Doporučen restart"
exit 0
