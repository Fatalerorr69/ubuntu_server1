#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/core-backup-dr.log"
BACKUP_ROOT="/srv/backups"
DATE=$(date +%F)

log() {
  echo "[`date '+%F %T'`] $1" | tee -a "$LOG_FILE"
}

require_root() {
  [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
}

require_root
log "START BACKUP & DR"

###############################################################################
# FÁZE A – STRUKTURA
###############################################################################
mkdir -p "$BACKUP_ROOT/$DATE"

###############################################################################
# FÁZE B – KONFIGURAČNÍ DATA
###############################################################################
log "Záloha konfigurací"

tar czf "$BACKUP_ROOT/$DATE/etc.tar.gz" /etc
tar czf "$BACKUP_ROOT/$DATE/srv.tar.gz" /srv

###############################################################################
# FÁZE C – DOCKER
###############################################################################
if command -v docker >/dev/null; then
  log "Docker backup"
  docker ps -q | xargs -I{} docker inspect {} > "$BACKUP_ROOT/$DATE/docker.json"
fi

###############################################################################
# FÁZE D – ČISTĚNÍ STARÝCH ZÁLOH
###############################################################################
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} \;

###############################################################################
# FÁZE E – CRON
###############################################################################
log "Cron job"

cat << 'EOF' > /etc/cron.d/core-backup
0 3 * * * root /usr/local/bin/core-backup-dr.sh
EOF

cp "$0" /usr/local/bin/core-backup-dr.sh
chmod +x /usr/local/bin/core-backup-dr.sh

###############################################################################
# FINÁLE
###############################################################################
log "BACKUP & DR HOTOVO"
exit 0
