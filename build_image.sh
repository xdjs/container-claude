#!/bin/bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  echo "Run: cp .env.example .env  — then edit it with your details."
  exit 1
fi

source .env

# Validate required build variables
: "${GIT_USER_NAME:?Error: GIT_USER_NAME is not set in .env}"
: "${GIT_USER_EMAIL:?Error: GIT_USER_EMAIL is not set in .env}"

IMAGE="${IMAGE_NAME:-claude-code}"

echo "Building image '${IMAGE}'..."
docker build \
     --build-arg GIT_USER_NAME="${GIT_USER_NAME}" \
     --build-arg GIT_USER_EMAIL="${GIT_USER_EMAIL}" \
     --build-arg DOCKER_USER="${DOCKER_USER:-dev}" \
     --build-arg WORKSPACE_DIR="${WORKSPACE_DIR:-workspace}" \
     -t "${IMAGE}" .

echo "Done. Image '${IMAGE}' built successfully."
