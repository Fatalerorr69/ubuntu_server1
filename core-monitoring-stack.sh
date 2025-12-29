#!/usr/bin/env bash
set -e

apt install -y prometheus prometheus-node-exporter grafana

systemctl enable prometheus --now
systemctl enable prometheus-node-exporter --now
systemctl enable grafana-server --now

ufw allow 3000/tcp
