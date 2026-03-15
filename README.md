# Claude Code Sandbox

A Docker Compose setup for running [Claude Code](https://github.com/anthropics/claude-code) in a sandboxed container with network firewall restrictions. Based on the [official Anthropic devcontainer setup](https://github.com/anthropics/claude-code/tree/main/.devcontainer), but heavily modified to accommodate my personal dotfiles, toolchain preferences, and a standalone Docker Compose workflow instead of VS Code devcontainers. Host machine configs (zsh, git, SSH, GitHub CLI) are mounted in so the container feels like home.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- `~/Code` directory on your host machine
- SSH keys, git, zsh, and GitHub CLI configs in their standard locations (`~/.ssh`, `~/.gitconfig`, `~/.zshrc`, etc.)
- A terminal with a [Nerd Font](https://www.nerdfonts.com/) installed for Starship prompt glyphs

## Quick Start

```bash
# Build and start the container
docker compose up -d --build --remove-orphans

# Shell into the container
docker compose -p claude-sandbox exec claude-sandbox zsh

# Run Claude Code directly
docker compose -p claude-sandbox exec claude-sandbox claude

# Test workflow command
docker compose down -v && docker compose up -d --build --remove-orphans && docker compose exec claude-sandbox zsh
```

## Stopping

```bash
# Stop the container
docker compose down

# Stop and remove volumes (wipes Claude config)
docker compose down -v
```

## Rebuilding

After modifying the `Dockerfile`, `.env`, or to pick up new tool versions:

```bash
docker compose up -d --build --force-recreate --remove-orphans
```

## Configuration

All configuration is managed through the `.env` file:

### Build args

| Variable | Default | Description |
|---|---|---|
| `TZ` | `America/Los_Angeles` | Container timezone |
| `USERNAME` | `sophie` | Container user |
| `NVM_VERSION` | `0.40.4` | nvm version |
| `CLAUDE_CODE_VERSION` | `latest` | Claude Code version |
| `EAS_CLI_VERSION` | `latest` | EAS CLI version |
| `GIT_DELTA_VERSION` | `0.18.2` | git-delta version |
| `GO_VERSION` | `1.24.1` | Go version |

### Runtime environment

| Variable | Default | Description |
|---|---|---|
| `NODE_OPTIONS` | `--max-old-space-size=4096` | Node.js memory limit |
| `CLAUDE_CONFIG_DIR` | `/home/sophie/.claude` | Claude config path |
| `POWERLEVEL9K_DISABLE_GITSTATUS` | `true` | Disable Powerlevel10k git status |
| `LANG` / `LC_ALL` | `en_US.UTF-8` | Locale |
| `SHELL` | `/bin/zsh` | Default shell |
| `EDITOR` / `VISUAL` | `vim` | Default editor |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | — | GitHub PAT (set on host) |
| `ANTHROPIC_API_KEY` | — | Anthropic API key (set on host) |

## What's Inside

### Runtimes
- **Node.js** (LTS via nvm)
- **Bun**
- **Go** 1.24.1
- **Rust** (nightly via rustup)

### Tools
- **Claude Code** (`@anthropic-ai/claude-code`)
- **EAS CLI** (`eas-cli`)
- **git-delta** for better diffs
- **zoxide** (smarter `cd`)
- **eza** (modern `ls`)
- **fzf** (fuzzy finder)
- **Starship** prompt with custom sandbox config
- **GitHub CLI** (`gh`)

### Shell
- **zsh** with:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - zsh-autocomplete
- **FiraCode Nerd Font** for glyph rendering
- **vim** with syntax highlighting enabled

## Mounted Host Configs

| Host Path | Container Path | Mode |
|---|---|---|
| `~/Code` | `/home/sophie/Code` | read-write |
| `~/.zshrc` | `/home/sophie/.zshrc` | read-only |
| `~/.zshenv` | `/home/sophie/.zshenv` | read-only |
| `~/.zsh` | `/home/sophie/.zsh` | read-only |
| `~/.gitconfig` | `/home/sophie/.gitconfig` | read-only |
| `~/.gitconfig-karaconnect` | `/home/sophie/.gitconfig-karaconnect` | read-only |
| `~/.ssh` | `/home/sophie/.ssh` | read-only |
| `~/.claude-sandbox` | `/home/sophie/.claude-sandbox` | read-only |
| `~/.claude-karaconnect-sandbox` | `/home/sophie/.claude-karaconnect-sandbox` | read-only |

Config files are mounted read-only to prevent the container from modifying your host configs.

## Persistent Volumes

- **claude-config** — Claude Code settings and auth persist across container restarts
- **claude-karaconnect-config** — Claude Karaconnect config persistence

## Firewall

The container includes a firewall script (`init-firewall.sh`) that restricts outbound network access to only:

- GitHub (API, web, git)
- npm registry
- Anthropic API
- Sentry, Statsig
- VS Code marketplace

All other outbound traffic is blocked. This requires the `NET_ADMIN` and `NET_RAW` capabilities.

To activate the firewall manually inside the container:

```bash
sudo /usr/local/bin/init-firewall.sh
```
