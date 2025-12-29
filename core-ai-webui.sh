#!/usr/bin/env bash
set -e

docker run -d \
  --name open-webui \
  -p 3001:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
