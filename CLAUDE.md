# Claude Code Container

Docker-based isolated environment for running Claude Code with gh CLI and Playwright.

## Setup guide

When a user asks to set up this container (or you detect .env doesn't exist):

1. Copy .env.example to .env
2. Read the Configuration table in README.md to get variable names, defaults, and descriptions. Use these as the source of truth for option labels and default values in the questions below.
3. Use a single AskUserQuestion call with exactly 4 questions to gather all setup info at once:

   - Question 1 (header: "Git name"): Ask for the user's git commit name — open-ended, no options (user types their name via "Other")
   - Question 2 (header: "Git email"): Ask for the user's git commit email — open-ended, no options (user types their email via "Other")
   - Question 3 (header: "Config mode"): Ask how the container should get Claude settings. Read the "Claude config modes" section in README.md for the available modes and their descriptions. Mark the recommended option.
   - Question 4 (header: "GH_TOKEN"): Ask if the user has a GitHub personal access token ready.
     - Option 1: "Yes, let me paste it" — the token will be exported for this session
     - Option 2: "Skip for now" — they can set it later before running ./run.sh

4. After the user answers, ask (in plain text) if they want to customize the container name or host port, or use the defaults from README.md. Most users should just use defaults.
5. Write all answers into .env (use defaults from README.md for anything the user didn't customize)
6. If the user provided a GH_TOKEN, export it in the current shell session
7. Run ./build_image.sh to build the Docker image
8. Run ./run.sh to start the container (if GH_TOKEN was skipped, remind the user to export it first)

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
