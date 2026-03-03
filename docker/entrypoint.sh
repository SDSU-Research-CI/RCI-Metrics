#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CONFIG_FILE:-}" ]]; then
  echo "CONFIG_FILE is required and must point to an externally mounted config file." >&2
  echo "Example: /app/secret-config/config.yaml" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

echo "Running with external config: $CONFIG_FILE"
exec python /app/src/main.py "$CONFIG_FILE"
