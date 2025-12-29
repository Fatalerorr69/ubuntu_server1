#!/usr/bin/env bash
set -Eeuo pipefail

############################################
# CORE SERVER – AUTOMATICKÝ INSTALÁTOR
# Ubuntu Server 22.04 / 24.04
############################################

### === KONFIGURACE === ###
SERVER_NAME="core-server"
TIMEZONE="Europe/Prague"
LOCALE="cs_CZ.UTF-8"
ADMIN_USER="coreadmin"
SSH_PORT="22"

INSTALL_DESKTOP=true
INSTALL_THINLINC=true
INSTALL_DOCKER=true
INSTALL_MFA=true

THINLINC_SESSION_LIMIT=1
THINLINC_COMPRESSION="high"

LOG_FILE="/var/log/core-install.log"

############################################
# === INTERNÍ FUNKCE ===
############################################

log() {
  echo "[`date '+%F %T'`] $1" | tee -a "$LOG_FILE"
}

fail() {
  log "❌ CHYBA: $1"
  exit 1
}

require_root() {
  [[ $EUID -eq 0 ]] || fail "Spusť jako root"
}

pause_checkpoint() {
  log "🔒 KONTROLNÍ BOD – doporučen snapshot VM"
  sleep 3
}

############################################
# === FÁZE 0 – KONTROLY ===
############################################

require_root
pause_checkpoint
log "START INSTALACE CORE SERVERU"

############################################
# === FÁZE 1 – ZÁKLAD OS ===
############################################

log "FÁZE 1 – aktualizace systému"
apt update && apt full-upgrade -y

apt install -y \
  curl wget git unzip zip rsync \
  htop tmux net-tools \
  sudo ca-certificates gnupg \
  ufw fail2ban chrony \
  software-properties-common

log "nastavení času, locale, hostname"
timedatectl set-timezone "$TIMEZONE"
locale-gen "$LOCALE"
update-locale LANG="$LOCALE"
hostnamectl set-hostname "$SERVER_NAME"

############################################
# === FÁZE 2 – UŽIVATEL & STRUKTURA ===
############################################

log "FÁZE 2 – uživatel a adresáře"

id "$ADMIN_USER" &>/dev/null || useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ADMIN_USER

mkdir -p /srv/{core,modules,stacks,backups,logs}
chown -R "$ADMIN_USER":"$ADMIN_USER" /srv

############################################
# === FÁZE 3 – BEZPEČNOST ===
############################################

log "FÁZE 3 – SSH, firewall, fail2ban"

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

############################################
# === FÁZE 3.1 – MFA (TOTP) ===
############################################

if $INSTALL_MFA; then
  log "MFA – Google Authenticator"
  apt install -y libpam-google-authenticator
  grep -q pam_google_authenticator.so /etc/pam.d/sshd || \
    echo "auth required pam_google_authenticator.so nullok" >> /etc/pam.d/sshd
  sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart ssh
fi

pause_checkpoint

############################################
# === FÁZE 4 – DESKTOP (XFCE) ===
############################################

if $INSTALL_DESKTOP; then
  log "FÁZE 4 – grafické prostředí"
  apt install -y xfce4 xfce4-goodies xorg lightdm
  systemctl set-default graphical.target
fi

############################################
# === FÁZE 5 – THINLINC ===
############################################

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

############################################
# === FÁZE 6 – DOCKER + PORTAINER ===
############################################

if $INSTALL_DOCKER; then
  log "FÁZE 6 – Docker"
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

############################################
# === FINÁLE ===
############################################

log "✅ INSTALACE DOKONČENA"
log "→ restart doporučen"
log "→ přihlaš se jako $ADMIN_USER"
log "→ ThinLinc: port 5901"
log "→ Portainer: https://IP:9443"

exit 0
