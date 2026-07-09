#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Log Work Activity
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 📝
# @raycast.argument1 { "type": "text", "placeholder": "what are you working on?", "optional": false }
# @raycast.packageName Daily Log

# Documentation:
# @raycast.description Quickly log a work activity with timestamp. Just describe what you did.
# @raycast.author Chancellor
#
# Usage: just type what you did, e.g. "helped Roman with Terraform state migration"
# Categories are auto-assigned later by the daily-log Claude Code skill.

MICRO_LOG_PATH="${HOME}/.config/daily-log/micro-log.md"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)

# Ensure the file and directory exist
mkdir -p "$(dirname "${MICRO_LOG_PATH}")"
touch "${MICRO_LOG_PATH}"

# Check if today's header exists, add it if not
if ! grep -q "## ${TODAY}" "${MICRO_LOG_PATH}" 2>/dev/null; then
  echo "" >> "${MICRO_LOG_PATH}"
  echo "## ${TODAY}" >> "${MICRO_LOG_PATH}"
fi

echo "- ${NOW} | $1" >> "${MICRO_LOG_PATH}"

echo "Logged: $1"
