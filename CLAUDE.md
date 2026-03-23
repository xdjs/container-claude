# Claude Code Container

Docker-based isolated environment for running Claude Code with gh CLI and Playwright.

## Setup guide

When a user asks to set up this container (or you detect .env doesn't exist):

1. Copy .env.example to .env
2. Ask the user for their name and email, fill in GIT_USER_NAME and GIT_USER_EMAIL
3. Ask if they want to import their existing Claude settings:
   - "seed" — copy host config once (recommended for most users)
   - "mount" — share config live between host and container
   - "fresh" — start clean, log in inside the container
   Set CLAUDE_CONFIG in .env accordingly.
4. Run ./build_image.sh to build the Docker image
5. Tell the user to: export GH_TOKEN=ghp_... && ./run.sh

## Inside the container

After entering the container, the typical workflow is:
- git clone a repo, cd into it, npm install
- npx playwright install chromium (if needed)
- claude --dangerously-skip-permissions

## Scripts

- ./build_image.sh — builds the Docker image from .env config
- ./run.sh — creates or restarts the container
- ./destroy.sh — tears down container and volumes (with confirmation)

## Conventions

- Shell scripts use set -euo pipefail and quote all variables
- All configurable values live in .env, not hard-coded in scripts
