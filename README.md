# Claude Code Sandbox

A Docker Compose setup for running [Claude Code](https://github.com/anthropics/claude-code) in a sandboxed container with network firewall restrictions. Host machine configs (zsh, git, SSH, starship) are mounted in so the container feels like home.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- `~/Code` directory on your host machine
- SSH keys, git, zsh, and starship configs in their standard locations (`~/.ssh`, `~/.gitconfig`, `~/.zshrc`, etc.)

## Quick Start

```bash
# Build and start the container
docker compose up -d --build --remove-orphans

# Shell into the container
docker compose exec claude-sandbox zsh

# Run Claude Code directly
docker compose exec claude-sandbox claude
```

## Stopping

```bash
# Stop the container
docker compose down

# Stop and remove volumes (wipes bash history and Claude config)
docker compose down -v
```

## Rebuilding

After modifying the `Dockerfile` or to pick up a new Claude Code version:

```bash
docker compose up -d --build --force-recreate --remove-orphans
```

## What's Inside

- **Debian Trixie** base image
- **Node.js 20** and **Bun** runtimes
- **Claude Code** (`@anthropic-ai/claude-code`)
- **zsh** with Powerlevel10k theme, fzf, and git integration
- **git-delta** for better diffs
- **Network firewall** restricting outbound traffic to GitHub, npm, Anthropic API, and a few other allowed domains

## Mounted Host Configs

| Host Path | Container Path | Mode |
|---|---|---|
| `~/Code` | `/home/sophie/Code` | read-write |
| `~/.zshrc` | `/home/sophie/.zshrc` | read-only |
| `~/.zshenv` | `/home/sophie/.zshenv` | read-only |
| `~/.zsh` | `/home/sophie/.zsh` | read-only |
| `~/.zsh_history` | `/home/sophie/.zsh_history` | read-write |
| `~/.gitconfig` | `/home/sophie/.gitconfig` | read-only |
| `~/.gitconfig-karaconnect` | `/home/sophie/.gitconfig-karaconnect` | read-only |
| `~/.config/gh` | `/home/sophie/.config/gh` | read-only |
| `~/.ssh` | `/home/sophie/.ssh` | read-only |
| `~/.config/starship.toml` | `/home/sophie/.config/starship.toml` | read-only |

Config files are mounted read-only to prevent the container from modifying your host configs.

## Persistent Volumes

- **bash-history** — shell history persists across container restarts
- **claude-config** — Claude Code settings and auth persist across container restarts

## Firewall

The container runs a firewall script (`init-firewall.sh`) on startup that restricts outbound network access to only:

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
