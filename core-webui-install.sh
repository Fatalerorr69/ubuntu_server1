#!/usr/bin/env bash
set -e

apt install -y python3 python3-venv python3-pip nginx

mkdir -p /srv/webui
cd /srv/webui

python3 -m venv venv
source venv/bin/activate

pip install fastapi uvicorn psutil python-multipart
