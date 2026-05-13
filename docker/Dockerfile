###############################################################################
###############################################################################
#################### RUN DOCKER BUILD IN PARENT DIR   #########################
## docker build --no-cache -t east01/rcimetrics:tag -f docker/Dockerfile .  ##
###############################################################################

# Use official Python 3.13 image from Docker Hub
FROM python:3.13-slim AS base

# Set working directory inside the container
WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/east-01/AutoMetrics.git /app/

# Install dependencies
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy your application code
COPY rci_plugins/ /app/plugins/rci_plugins/

# Create the entrypoint in-image so the build does not depend on an
# additional script path being present in the build context.
RUN cat <<'EOF' > /entrypoint.sh
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
EOF
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
