#!/usr/bin/env bash
MODULES="/opt/core-modules"

git clone https://repo/core-modules.git $MODULES || true
cd $MODULES && git pull

for m in *.sh; do
  bash "$m"
done
