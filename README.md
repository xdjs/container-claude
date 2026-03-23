# Claude Code Container

Docker-based Claude Code environment with gh CLI auth and Playwright support.

## Quick start

```bash
cp .env.example .env
# Edit .env with your name, email, and preferences (see Configuration below)
./build_image.sh
export GH_TOKEN=ghp_...
./run.sh
```

Or open this repo with Claude Code and say "set this up" — the CLAUDE.md file will guide it through configuration interactively.

## Configuration

Edit `.env` to customize your setup. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | (required) | Your name for git commits |
| `GIT_USER_EMAIL` | (required) | Your email for git commits |
| `CONTAINER_NAME` | `claude-dev` | Docker container name |
| `IMAGE_NAME` | `claude-code` | Docker image name |
| `HOST_PORT` | `3000` | Host port mapped to container port 3000 |
| `CLAUDE_CONFIG` | `fresh` | How to handle Claude settings (see below) |
| `GH_TOKEN` | (none) | GitHub personal access token for gh CLI auth (see below) |
| `ANTHROPIC_AUTH_TOKEN` | (none) | Claude auth token from `claude setup-token` (see below) |
| `ANTHROPIC_API_KEY` | (none) | Anthropic API key for direct API auth (see below) |

### GitHub token

`GH_TOKEN` is passed into the container as an environment variable. The gh CLI picks it up automatically — no `gh auth login` needed. It also powers `git push`/`pull` via the credential helper.

Export it in your shell before running `./run.sh`:

```bash
export GH_TOKEN=ghp_...
```

If not set, `run.sh` will warn you and ask whether to continue without GitHub authentication.

### Claude authentication

By default, Claude Code prompts for interactive login (`/login`) inside the container. To skip that, export one of these tokens in your host shell before running `./run.sh`:

- **`ANTHROPIC_AUTH_TOKEN`** (preferred) — An OAuth-derived token. Generate it on the host with `claude setup-token`, then export the value:
  ```bash
  export ANTHROPIC_AUTH_TOKEN=<token-from-setup-token>
  ```
- **`ANTHROPIC_API_KEY`** (alternative) — A direct Anthropic API key from console.anthropic.com:
  ```bash
  export ANTHROPIC_API_KEY=sk-ant-...
  ```

**Precedence**: `ANTHROPIC_AUTH_TOKEN` > `ANTHROPIC_API_KEY` > interactive OAuth via `/login`.

If neither is set, Claude works normally and prompts for login inside the container. Both variables are passed as environment variables (never written to disk), following the same pattern as `GH_TOKEN`.

### Claude config modes

Control how the container gets your Claude Code settings via `CLAUDE_CONFIG`:

- **`fresh`** (default) — Empty start. No host settings are carried over. Auth is handled separately (see Claude authentication above).
- **`seed`** — On first container creation, copies your host `~/.claude/` and `~/.claude.json` into the container volume. This carries over **settings and preferences only** — OAuth tokens are machine-bound and won't work in the container. Auth is handled separately via environment variables or interactive login. After seeding, host and container are independent.
- **`mount`** — Bind mounts your host `~/.claude/` and `~/.claude.json` directly into the container. Carries over settings and preferences. Auth is still handled separately — mounted OAuth tokens are machine-bound and may not work inside the container. Changes inside the container affect your host and vice versa.

## Build

```bash
./build_image.sh
```

Rebuild when you change build-time variables in `.env` (`GIT_USER_NAME`, `GIT_USER_EMAIL`, `DOCKER_USER`, `WORKSPACE_DIR`).

No rebuild needed for runtime variables (`HOST_PORT`, `CLAUDE_CONFIG`, `GH_TOKEN`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY`).

## Run

```bash
export GH_TOKEN=ghp_...
export ANTHROPIC_AUTH_TOKEN=...   # optional, from claude setup-token
./run.sh
```

If `GH_TOKEN` is not set, the script will warn you and ask whether to continue without GitHub authentication.

If the container already exists, `run.sh` restarts it. To start fresh, destroy it first (see below).

## Destroy

```bash
./destroy.sh
```

Removes the container and its volumes (config + workspace) after prompting for confirmation.

## Session workflow (inside container)

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
npm install
npx playwright install chromium
claude --dangerously-skip-permissions
```

## Playwright config

Add to `playwright.config.ts` to allow running in the container:

```ts
use: {
  launchOptions: {
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  },
}
```

## Security

- **GH_TOKEN**: Export in your shell rather than storing in `.env`. If you do store it in `.env`, the file is gitignored by default.
- **ANTHROPIC_AUTH_TOKEN / ANTHROPIC_API_KEY**: Same approach as GH_TOKEN — export in your shell, never stored in the image or filesystem.
- **Container hardening**: The container runs with all Linux capabilities dropped except the minimum needed (CHOWN, DAC_OVERRIDE, FOWNER, SETGID, SETUID, SYS_CHROOT, NET_BIND_SERVICE). Memory is capped at 8 GB with a 512 process limit.
- **Non-root user**: The container runs as a non-root user (`dev` by default).

## Troubleshooting

**Port already in use**: Change `HOST_PORT` in `.env` to a different port.

**Container already exists**: `run.sh` will restart the existing container. To recreate it, run `./destroy.sh` first, then `./run.sh`.

**Claude prompts for login despite using `seed` or `mount` mode**: Config modes carry over settings and preferences only — OAuth tokens are machine-bound and don't transfer into containers. Use `ANTHROPIC_AUTH_TOKEN` (from `claude setup-token`) or `ANTHROPIC_API_KEY` to authenticate without interactive login. See [Claude authentication](#claude-authentication) above.

## Notes

- `~/.claude` is persisted via a named Docker volume (`<container-name>-config`) across sessions
- `GH_TOKEN` is picked up natively by gh CLI — no `gh auth login` needed
- Playwright browsers are installed per session to stay version-matched to your project
- All work exits the container via git push
