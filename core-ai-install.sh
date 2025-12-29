#!/usr/bin/env bash
set -e

echo "[AI] Instalace Ollama…"

curl -fsSL https://ollama.com/install.sh | sh

systemctl enable ollama --now

sleep 3
ollama --version
