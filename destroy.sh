#!/bin/bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  exit 1
fi

source .env

CONTAINER="${CONTAINER_NAME:-claude-dev}"
IMAGE="${IMAGE_NAME:-claude-code}"

echo "This will permanently delete:"
echo "  - Container: ${CONTAINER}"
echo "  - Volume:    ${CONTAINER}-config"
echo "  - Volume:    ${CONTAINER}-workspace"
echo "  - Image:     ${IMAGE}"
echo ""
read -r -p "Are you sure? [y/N] " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

docker rm -f "${CONTAINER}" 2>/dev/null || true
docker volume rm "${CONTAINER}-config" 2>/dev/null || true
docker volume rm "${CONTAINER}-workspace" 2>/dev/null || true
docker rmi "${IMAGE}" 2>/dev/null || true
echo "Done. Container, volumes, and image removed."
