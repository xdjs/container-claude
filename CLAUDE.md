# Claude Code Container

Docker-based isolated environment for running Claude Code with gh CLI and Playwright.

## Setup guide

When a user asks to set up this container (or you detect .env doesn't exist):

1. Copy .env.example to .env
2. Use the AskUserQuestion tool to gather all setup info in a wizard-like flow. Ask these questions across two AskUserQuestion calls (max 4 questions per call):

   **Call 1 — Identity and config mode:**
   - Question 1 (header: "Git name"): "What name should be used for git commits?" — open-ended, no options (user types their name via "Other")
   - Question 2 (header: "Git email"): "What email should be used for git commits?" — open-ended, no options (user types their email via "Other")
   - Question 3 (header: "Config mode"): "How should the container get your Claude settings?"
     - Option 1: "seed (Recommended)" — "Copy your host ~/.claude config into the container on first run. You get your auth and settings without re-logging in."
     - Option 2: "mount" — "Bind mount host config directly. Host and container share state — changes in one affect the other."
     - Option 3: "fresh" — "Start clean. You'll log in to Claude interactively inside the container."

   **Call 2 — Optional settings:**
   - Question 1 (header: "Container"): "What should the Docker container be named?"
     - Option 1: "claude-dev (Recommended)" — "Default container name"
     - (user can pick default or type a custom name via "Other")
   - Question 2 (header: "Port"): "Which host port should map to the container's port 3000?"
     - Option 1: "3000 (Recommended)" — "Default port"
     - (user can pick default or type a custom port via "Other")
   - Question 3 (header: "GH_TOKEN"): "Do you have a GitHub personal access token ready?"
     - Option 1: "Yes, let me paste it" — "You'll paste your ghp_... token and it will be exported for this session"
     - Option 2: "Skip for now" — "You can set it later with: export GH_TOKEN=ghp_... before running ./run.sh"

3. Write all answers into .env (use defaults for anything the user didn't customize)
4. If the user provided a GH_TOKEN, export it in the current shell session
5. Run ./build_image.sh to build the Docker image
6. Run ./run.sh to start the container (if GH_TOKEN was skipped, remind the user to export it first)

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
