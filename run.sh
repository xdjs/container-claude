#!/bin/bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  echo "Run: cp .env.example .env  — then edit it with your details."
  exit 1
fi

source .env

# Assign with defaults
CONTAINER="${CONTAINER_NAME:-claude-dev}"
DOCKER_USER="${DOCKER_USER:-dev}"
WORKSPACE_DIR="${WORKSPACE_DIR:-workspace}"
IMAGE="${IMAGE_NAME:-claude-code}"
HOST_PORT="${HOST_PORT:-3000}"
CLAUDE_CONFIG="${CLAUDE_CONFIG:-fresh}"

# Validate GH_TOKEN
if [ -z "${GH_TOKEN:-}" ]; then
  echo "Warning: GH_TOKEN is not set. gh CLI will not be authenticated."
  echo "Export it before running:  export GH_TOKEN=ghp_..."
  echo ""
  read -r -p "Continue without GH_TOKEN? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Restart existing container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Restarting existing container '${CONTAINER}'..."
  docker start -ai "${CONTAINER}"
  exit 0
fi

# Build docker run arguments for new container
echo "Creating new container '${CONTAINER}' from image '${IMAGE}'..."

RUN_ARGS=(
  --name "${CONTAINER}"
  -v "${CONTAINER}-workspace:/${WORKSPACE_DIR}"
  -p "${HOST_PORT}:3000"
  --cap-drop ALL
  --cap-add CHOWN
  --cap-add DAC_OVERRIDE
  --cap-add FOWNER
  --cap-add SETGID
  --cap-add SETUID
  --cap-add SYS_CHROOT
  --cap-add NET_BIND_SERVICE
  --memory 8g
  --pids-limit 512
)

# Pass GH_TOKEN if set
if [ -n "${GH_TOKEN:-}" ]; then
  RUN_ARGS+=(-e "GH_TOKEN")
fi

# Handle Claude config mode
case "${CLAUDE_CONFIG}" in
  mount)
    echo "Config mode: mount (sharing host ~/.claude and ~/.claude.json)"
    if [ -d "$HOME/.claude" ]; then
      RUN_ARGS+=(-v "$HOME/.claude:/home/${DOCKER_USER}/.claude")
    else
      echo "Warning: ~/.claude not found on host, skipping mount."
    fi
    if [ -f "$HOME/.claude.json" ]; then
      RUN_ARGS+=(-v "$HOME/.claude.json:/home/${DOCKER_USER}/.claude.json")
    else
      echo "Warning: ~/.claude.json not found on host, skipping mount."
    fi
    ;;
  seed)
    echo "Config mode: seed (copying host config into container on first run)"
    RUN_ARGS+=(-v "${CONTAINER}-config:/home/${DOCKER_USER}/.claude")
    ;;
  fresh)
    echo "Config mode: fresh (clean start)"
    RUN_ARGS+=(-v "${CONTAINER}-config:/home/${DOCKER_USER}/.claude")
    ;;
  *)
    echo "Error: CLAUDE_CONFIG must be 'fresh', 'seed', or 'mount' (got '${CLAUDE_CONFIG}')"
    exit 1
    ;;
esac

# For seed mode, use create + cp + start so we can copy files before first session
if [ "${CLAUDE_CONFIG}" = "seed" ]; then
  docker create -it "${RUN_ARGS[@]}" "${IMAGE}" bash --login

  # Seed from host if files exist
  if [ -d "$HOME/.claude" ]; then
    echo "Seeding ~/.claude/ from host..."
    docker cp "$HOME/.claude/." "${CONTAINER}:/home/${DOCKER_USER}/.claude/"
  else
    echo "Warning: ~/.claude not found on host, skipping seed."
  fi
  if [ -f "$HOME/.claude.json" ]; then
    echo "Seeding ~/.claude.json from host..."
    docker cp "$HOME/.claude.json" "${CONTAINER}:/home/${DOCKER_USER}/.claude.json"
  else
    echo "Warning: ~/.claude.json not found on host, skipping seed."
  fi

  # Fix ownership — docker cp copies files as root
  docker start "${CONTAINER}"
  docker exec -u root "${CONTAINER}" chown -R "${DOCKER_USER}:${DOCKER_USER}" \
    "/home/${DOCKER_USER}/.claude" "/home/${DOCKER_USER}/.claude.json" 2>/dev/null || true
  docker stop "${CONTAINER}" > /dev/null

  docker start -ai "${CONTAINER}"
else
  docker run -it "${RUN_ARGS[@]}" "${IMAGE}" bash --login
fi
