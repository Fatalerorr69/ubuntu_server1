#!/usr/bin/env bash
MODEL="llama3.1:8b"

echo "AI Chat – napiš 'exit' pro ukončení"
while true; do
  read -rp "YOU> " Q
  [[ "$Q" == "exit" ]] && break
  ollama run "$MODEL" "$Q"
done
