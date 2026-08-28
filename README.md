# AI Dotfiles

Centralized AI coding assistant configs. Write once, sync everywhere.

Uses [rulesync](https://github.com/dyoshikawa/rulesync) to generate tool-specific configs for Claude Code and Codex CLI from a single source of truth.

## Setup

```bash
# 1. Install rulesync
npm install -g rulesync

# 2. Clone and set up
git clone <repository-url>
cd ai-dotfiles
make setup
```

That's it. The setup script symlinks `~/.rulesync` to this repo and runs the first sync.

## Usage

After editing any config files, sync your changes:

```bash
make sync
```

Other commands:

```bash
make dry-run          # Preview what will be generated
make check            # Verify generated files haven't drifted
make update-vendored  # Pull the latest version of upstream-authored skills
```

## Vendored Skills

Some skills are authored elsewhere and copied in rather than written here. They're
listed in `vendored-skills.txt` (skill name plus the raw URL of its `SKILL.md`):

| Skill | Upstream |
|-------|----------|
| `humanizer` | [blader/humanizer](https://github.com/blader/humanizer) (MIT) |
| `bro` | [dmmulroy/skills](https://github.com/dmmulroy/skills/tree/main/bro) (MIT) |

Because the copies are committed, a fresh machine gets them from `make setup` alone
— no extra install step. To pick up upstream changes, run `make update-vendored`
then `make sync`. Don't hand-edit a vendored `SKILL.md`; the refresh overwrites it.

## What's Inside

All configs live in `.rulesync/`:

| Path | Purpose |
|------|---------|
| `rules/` | Coding guidelines — style, TypeScript, architecture |
| `commands/` | Slash commands (`/commit`, `/create-pr`) |
| `subagents/` | Specialized agents (planner) |
| `skills/` | Reusable skill sets (find-skills, frontend-design) |
| `.aiignore` | Files to hide from AI tools |

## Adding Configs

Create a `.md` file in the appropriate directory. Each file needs frontmatter:

```markdown
---
root: true
targets: ["*"]
description: "What this config does"
globs: ["**/*"]
---

Your instructions here.
```

- `targets: ["*"]` sends to all AI tools
- `targets: ["claudecode", "codexcli"]` sends to specific tools only
- `globs` controls which files the rule applies to

Then run `make sync`.

## Repo Structure

```
ai-dotfiles/
├── .rulesync/           # Source of truth (edit these)
│   ├── rules/           # code-style.md (style, TS, architecture)
│   ├── commands/        # commit, create-pr
│   ├── subagents/       # planner
│   ├── skills/          # find-skills, frontend-design, humanizer
│   └── .aiignore
├── scripts/
│   └── update-vendored.sh  # Refreshes vendored skills from upstream
├── vendored-skills.txt   # Manifest of upstream-authored skills
├── rulesync.jsonc        # Rulesync config (targets, features)
├── setup.sh              # One-time setup (symlink + first sync)
├── Makefile              # sync, check, dry-run, setup, update-vendored
└── README.md
```

## Learn More

- [rulesync documentation](https://github.com/dyoshikawa/rulesync)
- [Skills ecosystem](https://skills.sh/)
