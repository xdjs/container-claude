#!/bin/bash
set -e

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  echo "Run: cp .env.example .env  — then edit it with your details."
  exit 1
fi

source .env

CONTAINER="${CONTAINER_NAME:-claude-dev}"
DOCKER_USER="${DOCKER_USER:-dev}"
WORKSPACE_DIR="${WORKSPACE_DIR:-workspace}"
IMAGE="${IMAGE_NAME:-claude-code}"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Restarting existing container..."
  docker start -ai $CONTAINER
else
  echo "Creating new container..."
  docker run -it \
    --name $CONTAINER \
    -e GH_TOKEN="${GH_TOKEN}" \
    -v ${CONTAINER}-config:/home/${DOCKER_USER}/.claude \
    -v ${CONTAINER}-workspace:/${WORKSPACE_DIR} \
    -p 3000:3000 \
    $IMAGE \
    bash --login
fi
