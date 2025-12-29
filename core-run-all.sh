#!/usr/bin/env bash
set -e

bash core-platform-install.sh
bash core-os-postsetup.sh
bash core-user-profiles.sh
bash core-backup-dr.sh
bash core-wireguard-mfa.sh
bash core-web-rbac.sh
bash core-ha-prep.sh
