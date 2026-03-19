#!/bin/bash
set -e

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  echo "Run: cp .env.example .env  — then edit it with your details."
  exit 1
fi

source .env

docker build \
     --build-arg GIT_USER_NAME="${GIT_USER_NAME}" \
     --build-arg GIT_USER_EMAIL="${GIT_USER_EMAIL}" \
     --build-arg DOCKER_USER="${DOCKER_USER:-dev}" \
     --build-arg WORKSPACE_DIR="${WORKSPACE_DIR:-workspace}" \
     -t "${IMAGE_NAME:-claude-code}" .
