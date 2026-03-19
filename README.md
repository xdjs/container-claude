# Claude Code Container

Docker-based Claude Code environment with gh CLI auth and Playwright support.

## Setup

```bash
cp .env.example .env
# Edit .env with your name, email, container name, and username
```

## Build

```bash
./build_image.sh
```

## Run

```bash
export GH_TOKEN=ghp_...
./run.sh
```

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

## Notes

- On first run, `claude` will prompt you to log in interactively — credentials are persisted in the `~/.claude` volume
- `~/.claude` is persisted via a named Docker volume (`<container-name>-config`) across sessions
- `GH_TOKEN` is picked up natively by gh CLI — no `gh auth login` needed
- Playwright browsers are installed per session to stay version-matched to your project
- All work exits the container via git push
