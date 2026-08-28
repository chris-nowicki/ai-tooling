# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Dotfiles — a centralized configuration management system for AI coding assistants. It uses [rulesync](https://github.com/dyoshikawa/rulesync) to maintain a single source of truth in `.rulesync/` and generate tool-specific configs for Claude Code and Codex CLI.

This is a configuration-only repository (no package.json, no build system, no tests).

## Key Commands

```bash
# Initial setup — symlinks ~/.rulesync and runs first sync
make setup

# After editing any files in .rulesync/, regenerate global configs
make sync

# Preview what will be generated without writing files
make dry-run

# Re-download skills vendored from upstream repos (see vendored-skills.txt)
make update-vendored

# Verify generated files haven't drifted from source
make check
```

## Architecture

### How It Works

1. `.rulesync/` is the source of truth for all AI tool configurations
2. `setup.sh` symlinks `.rulesync/` to `~/.rulesync` for global access and runs initial sync
3. Running `make sync` (or `rulesync generate -g`) generates tool-specific config files (`CLAUDE.md`, `AGENTS.md`, `~/.agents/skills/`, etc.)
4. `rulesync.jsonc` controls which AI tools (`targets`: `["*"]` for all) and config types (`features`) are generated

### .rulesync/ Directory

| Path | Purpose |
|------|---------|
| `rules/` | Coding guidelines (`code-style.md` — covers style, TypeScript, and architecture). Frontmatter `root: true` means it applies globally. |
| `commands/` | Custom slash commands (e.g., `/commit`, `/create-pr`). Each `.md` file becomes a command. |
| `subagents/` | Specialized AI agent definitions (e.g., `planner.md` — read-only analysis agent). |
| `skills/` | Reusable instruction sets. Each skill is a directory containing a `SKILL.md`. Some are vendored from upstream repos — see below. |
| `.aiignore` | Patterns for files AI tools should ignore (like `.gitignore` for AI). |

### Vendored Skills

Skills listed in `vendored-skills.txt` (name + raw `SKILL.md` URL) are copied from
upstream repos, not authored here. `scripts/update-vendored.sh` re-downloads them and
overwrites the local copy, so never hand-edit a vendored `SKILL.md` — put local
changes in a separate skill or rule instead. The copies are committed, so `make setup`
on a new machine installs them without network access to the upstream repos.

Currently vendored: `humanizer` (from [blader/humanizer](https://github.com/blader/humanizer), MIT)
and `bro` (from [dmmulroy/skills](https://github.com/dmmulroy/skills), MIT).

### Configuration Files

- **`rulesync.jsonc`** — Main config. `targets: ["*"]` sends to all AI tools; `features` array controls what types of configs are generated; `delete: true` cleans up stale generated files.
- **`Makefile`** — Shortcuts for `sync`, `check`, `dry-run`, and `setup`.
- **Frontmatter in `.md` files** — Each config file has YAML frontmatter with a `targets` field. Use `["*"]` for all tools or specify specific targets like `["claudecode", "codexcli"]`.

### External Dependencies

- `rulesync` (npm package) — config generation engine
- `gh` (GitHub CLI) — used by `/create-pr` command
