#!/bin/bash
# Refresh skills vendored from upstream repos, as listed in vendored-skills.txt.
# Overwrites each skill's SKILL.md — never hand-edit vendored skills.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$REPO_DIR/vendored-skills.txt"

if [ ! -f "$MANIFEST" ]; then
  echo "Error: $MANIFEST not found"
  exit 1
fi

while read -r name url; do
  # Skip comments and blank lines
  case "$name" in
    ''|\#*) continue ;;
  esac

  dest_dir="$REPO_DIR/.rulesync/skills/$name"
  dest="$dest_dir/SKILL.md"
  tmp="$(mktemp)"

  echo "Fetching $name from $url"
  if ! curl -fsSL "$url" -o "$tmp"; then
    echo "  Error: download failed, leaving existing $name untouched"
    rm -f "$tmp"
    exit 1
  fi

  # A SKILL.md must start with YAML frontmatter; guard against fetching an error page
  if ! head -n 1 "$tmp" | grep -q '^---$'; then
    echo "  Error: response is not a SKILL.md (no frontmatter), leaving $name untouched"
    rm -f "$tmp"
    exit 1
  fi

  mkdir -p "$dest_dir"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    echo "  Already up to date"
    rm -f "$tmp"
  else
    mv "$tmp" "$dest"
    echo "  Updated $dest"
  fi
done < "$MANIFEST"

echo ""
echo "Done. Run 'make sync' to regenerate global configs."
