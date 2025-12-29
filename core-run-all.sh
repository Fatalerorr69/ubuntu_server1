#!/usr/bin/env bash
set -e

bash core-platform-install.sh
bash core-os-postsetup.sh
bash core-security-hardening.sh
bash core-logging-central.sh
bash core-monitoring-stack.sh
bash core-backup-dr.sh
bash core-thinlinc-full.sh
bash core-roles-mfa.sh
bash core-wireguard-mfa.sh
bash core-webui-install.sh
bash core-webui-service.sh
bash core-webui-nginx.sh
bash core-aiops-engine.sh
bash core-selfcheck.sh
