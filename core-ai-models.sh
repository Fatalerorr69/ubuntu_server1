#!/usr/bin/env bash
set -e

MODELS=(
  "llama3.1:8b"
  "mistral:7b"
  "phi3:medium"
  "codellama:7b"
)

for m in "${MODELS[@]}"; do
  echo "[AI] Stahuji model $m"
  ollama pull "$m"
done
