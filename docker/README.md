# Docker Usage

This folder contains the Docker image definition for running the RCI Metrics
plugin together with a cloned copy of
[AutoMetrics](https://github.com/east-01/AutoMetrics).

## What This Image Does

The Dockerfile:

- Starts from `python:3.13-slim`
- Clones `east-01/AutoMetrics` into `/app`
- Installs AutoMetrics Python dependencies
- Copies this repository's `rci_plugins/` into `/app/plugins/rci_plugins/`
- Runs `python /app/src/main.py "$CONFIG_FILE"`

## Build

Build from the repository root, not from the `/docker/` directory. The
Dockerfile expects the repo root as the build context so it can copy
`rci_plugins/`.

```bash
docker build -t east01/rcimetrics:tag -f docker/Dockerfile .
```
Mac Users on M1 Macbook building for x86 processors can use 
```bash
docker build --platform linux/amd64 -t autotm-rci-metrics:v1.0 -f docker/Dockerfile 
```

## Required Runtime Input

The container requires a `CONFIG_FILE` environment variable that points to a
config file mounted into the container.

If `CONFIG_FILE` is missing, or the file does not exist inside the container,
startup will fail.

## Run

Example:

```bash
docker run --rm \
  -e CONFIG_FILE=/app/secret-config/monthly.yaml \
  -v "$(pwd)/configs:/app/secret-config:ro" \
  east01/rcimetrics:tag
```

In this example:

- `$(pwd)/configs` is mounted read-only into the container
- `monthly.yaml` must exist inside your local `configs/` directory
- `CONFIG_FILE` points to the mounted file path inside the container

## Using A Different Config

You can point to any mounted config file, for example:

```bash
docker run --rm \
  -e CONFIG_FILE=/app/secret-config/tidesplit.yaml \
  -v "$(pwd)/configs:/app/secret-config:ro" \
  east01/rcimetrics:tag
```

## Upload To Docker Hub (Optional)

After building and verifying that it works, build and tag the image with your Docker Hub username and a version tag:

```bash
docker build -t <dockerhub-username>/rcimetrics:v1.0 -f docker/Dockerfile .
```

Log in to Docker Hub:

```bash
docker login
```

Push the versioned tag:

```bash
docker push <dockerhub-username>/rcimetrics:v1.0
```

If you also want a `latest` tag:

```bash
docker tag <dockerhub-username>/rcimetrics:v1.0 <dockerhub-username>/rcimetrics:latest
docker push <dockerhub-username>/rcimetrics:latest
```

You can confirm the image name and tags from your local machine with:

```bash
docker images
```

## Next Steps

If you wish to run this on kubernetes, SLURM or another cluster, please follow README.md instructions in ``/manifest/`` folder

## Common Mistakes

- Building from `docker/` instead of the repo root. Use `-f docker/Dockerfile .`
- Setting `CONFIG_FILE` to a host path instead of a container path
- Forgetting to mount the config directory into the container
- Pointing `CONFIG_FILE` to a filename that does not exist in the mounted directory
