---
root: true
targets: ["*"]
description: "Global development guidelines: code style, TypeScript, architecture, git, and the work vault"
globs: ["**/*"]
---

# Code Style

- Use 2 spaces for indentation
- Use semicolons
- Use double quotes for strings
- Use trailing commas in multi-line objects and arrays

# TypeScript Guidelines

- Use TypeScript for all new code
- Follow consistent naming conventions
- Write self-documenting code with clear variable and function names
- Use meaningful comments for complex business logic

# Architecture Principles

- Organize code by feature, not by file type
- Keep related files close together
- Prefer composition over inheritance
- Use dependency injection for better testability
- Implement proper error handling
- Follow single responsibility principle

# Git & Commits

- Use Conventional Commits: `<type>[optional scope]: <description>`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
  - Lowercase type, imperative mood ("add" not "added"), concise description
  - Add a body to explain _what_ and _why_ when the change isn't obvious
- Branch off `main` before committing — never commit directly to `main`
- Open PRs with the `gh` CLI: descriptive title, and **no test section** in the PR body

# Work Vault

My work vault lives at `~/vaults/work` (git repo) — plain markdown, edited
in VS Code. It is the home for work notes, knowledge, daily logs, people
notes, and Claude Code reports. Use standard markdown links, not
`[[wikilinks]]`.

Rules that apply from ANY repo:

- **Reports**: when I ask you to write a report or summary, save it to
  `~/vaults/work/reports/YYYY-MM-DD <topic>.md` (today's date, short
  kebab-or-plain topic). Then append one line to today's daily note at
  `~/vaults/work/daily/YYYY-MM-DD.md`:
  `- 🤖 [<topic>](<../reports/YYYY-MM-DD <topic>.md>) — <one-line takeaway>`
  Create the daily note from the template if it doesn't exist yet.
- **Action items**: if a report or task surfaces todos, add them as
  `- [ ]` lines under the `## To file` section of today's daily note.
  Never track todos in the vault itself — Linear is the only source of
  truth for tracked work.
- **Git**: after writing to the vault, commit with message
  `vault: <what you did>` and push. Don't batch unrelated changes.
- The vault has its own CLAUDE.md with full structure and rules; consult
  it if you're working inside the vault.
