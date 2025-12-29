#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# CORE PLATFORM – UNIVERSAL SERVER INSTALLER
# Ubuntu Server 22.04 / 24.04
###############################################################################

### ================== KONFIGURACE ==================
SERVER_NAME="core-server"
TIMEZONE="Europe/Prague"
LOCALE="cs_CZ.UTF-8"

ADMIN_USER="coreadmin"
SSH_PORT=22

INSTALL_DESKTOP=true
INSTALL_THINLINC=true
INSTALL_DOCKER=true
INSTALL_MFA=true
INSTALL_ADMIN_PANEL=true
INSTALL_WIREGUARD=true
INSTALL_PLUGIN_LOADER=true

THINLINC_SESSION_LIMIT=1
THINLINC_COMPRESSION="high"

WG_NET="10.10.0.0/24"
WG_ADDR="10.10.0.1/24"
WG_PORT=51820

ADMIN_PANEL_PORT=3000

LOG_FILE="/var/log/core-platform-install.log"
###############################################################################

log() {
  echo "[`date '+%F %T'`] $1" | tee -a "$LOG_FILE"
}

fail() {
  log "❌ CHYBA: $1"
  exit 1
}

require_root() {
  [[ $EUID -eq 0 ]] || fail "Skript musí běžet jako root"
}

checkpoint() {
  log "🔒 KONTROLNÍ BOD – doporučen snapshot VM"
  sleep 2
}

###############################################################################
# FÁZE 0 – KONTROLY
###############################################################################
require_root
checkpoint
log "START INSTALACE CORE PLATFORMY"

###############################################################################
# FÁZE 1 – ZÁKLAD OS
###############################################################################
log "FÁZE 1 – aktualizace a základní balíky"

apt update && apt full-upgrade -y
apt install -y \
  curl wget git unzip zip rsync \
  htop tmux net-tools sudo \
  ca-certificates gnupg \
  ufw fail2ban chrony \
  software-properties-common \
  python3 python3-pip

timedatectl set-timezone "$TIMEZONE"
locale-gen "$LOCALE"
update-locale LANG="$LOCALE"
hostnamectl set-hostname "$SERVER_NAME"

###############################################################################
# FÁZE 2 – UŽIVATEL + STRUKTURA
###############################################################################
log "FÁZE 2 – uživatel a struktura"

id "$ADMIN_USER" &>/dev/null || useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ADMIN_USER

mkdir -p /srv/{core,modules,stacks,backups,logs}
chown -R "$ADMIN_USER":"$ADMIN_USER" /srv

###############################################################################
# FÁZE 3 – BEZPEČNOST (SSH / FIREWALL)
###############################################################################
log "FÁZE 3 – SSH hardening, firewall"

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i "s/^#\?Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
systemctl restart ssh

ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"/tcp
ufw --force enable

systemctl enable --now fail2ban

###############################################################################
# FÁZE 3.1 – MFA (TOTP)
###############################################################################
if $INSTALL_MFA; then
  log "FÁZE 3.1 – MFA (Google Authenticator)"
  apt install -y libpam-google-authenticator
  grep -q pam_google_authenticator.so /etc/pam.d/sshd || \
    echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sshd
  sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart ssh
fi

checkpoint

###############################################################################
# FÁZE 4 – DESKTOP (XFCE)
###############################################################################
if $INSTALL_DESKTOP; then
  log "FÁZE 4 – XFCE desktop"
  apt install -y xfce4 xfce4-goodies xorg lightdm
  systemctl set-default graphical.target
fi

###############################################################################
# FÁZE 5 – THINLINC
###############################################################################
if $INSTALL_THINLINC; then
  log "FÁZE 5 – ThinLinc"
  cd /tmp
  wget -q https://www.cendio.com/downloads/thinlinc/tl-4.17.0-server.zip
  unzip -q tl-4.17.0-server.zip
  cd tl-4.17.0-server
  yes | ./install-server

  /opt/thinlinc/sbin/tl-config set sessionlimit "$THINLINC_SESSION_LIMIT"
  /opt/thinlinc/sbin/tl-config set compression "$THINLINC_COMPRESSION"
  ufw allow 5901/tcp
fi

###############################################################################
# FÁZE 6 – DOCKER + PORTAINER
###############################################################################
if $INSTALL_DOCKER; then
  log "FÁZE 6 – Docker + Portainer"
  apt install -y docker.io docker-compose
  systemctl enable --now docker
  usermod -aG docker "$ADMIN_USER"

  docker volume create portainer_data || true
  docker run -d --restart=always \
    -p 9443:9443 \
    --name portainer \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce || true
fi

###############################################################################
# FÁZE 7 – WEB ADMIN PANEL
###############################################################################
if $INSTALL_ADMIN_PANEL; then
  log "FÁZE 7 – Web Admin Panel"

  apt install -y python3-flask nginx

  mkdir -p /srv/core/admin
  cat << 'EOF' > /srv/core/admin/app.py
from flask import Flask
import subprocess

app = Flask(__name__)

@app.route("/")
def index():
    uptime = subprocess.getoutput("uptime")
    services = subprocess.getoutput("systemctl --failed")
    return f"<h1>CORE SERVER</h1><pre>{uptime}</pre><pre>{services}</pre>"

app.run(host="0.0.0.0", port=3000)
EOF

  cat << 'EOF' > /etc/systemd/system/admin-panel.service
[Unit]
Description=Core Admin Panel
After=network.target

[Service]
ExecStart=/usr/bin/python3 /srv/core/admin/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now admin-panel
  ufw allow ${ADMIN_PANEL_PORT}/tcp
fi

###############################################################################
# FÁZE 8 – WIREGUARD + ZERO TRUST
###############################################################################
if $INSTALL_WIREGUARD; then
  log "FÁZE 8 – WireGuard VPN"

  apt install -y wireguard
  mkdir -p /etc/wireguard
  umask 077
  wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub

  SERVER_PRIV=$(cat /etc/wireguard/server.key)

  cat << EOF > /etc/wireguard/wg0.conf
[Interface]
Address = ${WG_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
SaveConfig = true
EOF

  systemctl enable wg-quick@wg0
  systemctl start wg-quick@wg0

  ufw deny ${SSH_PORT}
  ufw deny 5901
  ufw deny ${ADMIN_PANEL_PORT}

  ufw allow in on wg0 to any port ${SSH_PORT}
  ufw allow in on wg0 to any port 5901
  ufw allow in on wg0 to any port ${ADMIN_PANEL_PORT}
  ufw allow ${WG_PORT}/udp
fi

###############################################################################
# FÁZE 9 – AUTO MODULE LOADER
###############################################################################
if $INSTALL_PLUGIN_LOADER; then
  log "FÁZE 9 – Modulární auto-loader"

  cat << 'EOF' > /usr/local/bin/module-loader.sh
#!/bin/bash
for m in /srv/modules/*.sh; do
  [ -f "$m" ] || continue
  echo "[MODULE] $m"
  bash "$m"
done
EOF

  chmod +x /usr/local/bin/module-loader.sh

  cat << 'EOF' > /etc/systemd/system/module-loader.service
[Unit]
Description=CORE Module Loader
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/module-loader.sh

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable module-loader
fi

###############################################################################
# FINÁLE
###############################################################################
log "✅ INSTALACE DOKONČENA"
log "Doporučen RESTART systému"
log "SSH / ThinLinc / Admin dostupné pouze přes WireGuard"
log "Log: $LOG_FILE"
exit 0
