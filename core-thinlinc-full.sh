#!/usr/bin/env bash
set -e

wget https://www.cendio.com/downloads/server/tl-4.17.0-server.zip
unzip tl-*.zip
cd tl-*/ && sudo ./install-server

systemctl enable tlwebaccess --now
systemctl enable vsmserver --now

ufw allow 3000/tcp
ufw allow 5901/tcp
