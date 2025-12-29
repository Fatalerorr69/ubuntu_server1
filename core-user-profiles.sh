#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/core-user-profiles.log"

ADMIN_GROUP="core-admin"
USER_GROUP="core-user"

log() {
  echo "[`date '+%F %T'`] $1" | tee -a "$LOG_FILE"
}

require_root() {
  [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
}

require_root
log "START USER PROFILE SETUP"

###############################################################################
# FÁZE A – SKUPINY & ROLE
###############################################################################
log "FÁZE A – skupiny"

groupadd -f "$ADMIN_GROUP"
groupadd -f "$USER_GROUP"

###############################################################################
# FÁZE B – SUDO POLITIKY
###############################################################################
log "FÁZE B – sudo policy"

cat << 'EOF' > /etc/sudoers.d/core-admin
%core-admin ALL=(ALL) ALL
EOF

chmod 440 /etc/sudoers.d/core-admin

###############################################################################
# FÁZE C – LIMITY ZDROJŮ
###############################################################################
log "FÁZE C – limity"

cat << 'EOF' > /etc/security/limits.d/core-users.conf
@core-user hard nproc 512
@core-user soft nofile 4096
EOF

###############################################################################
# FÁZE D – SSH POLITIKY
###############################################################################
log "FÁZE D – SSH role enforcement"

grep -q AllowGroups /etc/ssh/sshd_config || \
echo "AllowGroups core-admin core-user" >> /etc/ssh/sshd_config

systemctl restart ssh

###############################################################################
# FÁZE E – THINLINC PROFILY
###############################################################################
if [ -d /opt/thinlinc ]; then
  log "FÁZE E – ThinLinc profily"

  /opt/thinlinc/sbin/tl-config set sessionlimit 1
  /opt/thinlinc/sbin/tl-config set loginbanner "AUTHORIZED ACCESS ONLY"
fi

###############################################################################
# FÁZE F – MFA VYNUCENÍ (ADMIN)
###############################################################################
log "FÁZE F – MFA enforcement"

sed -i 's/nullok//' /etc/pam.d/sshd

###############################################################################
# FINÁLE
###############################################################################
log "USER PROFILES HOTOVO"
exit 0
