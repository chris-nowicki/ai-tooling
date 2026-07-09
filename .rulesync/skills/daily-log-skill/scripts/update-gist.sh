#!/usr/bin/env bash
# update-gist.sh
# Creates or updates a daily log file in a GitHub Gist.
#
# Usage: ./update-gist.sh <gist_id> <entry_file> [date]
#   entry_file: path to the markdown entry to upload
#   date: defaults to today (YYYY-MM-DD)

set -euo pipefail

GIST_ID="${1:?Usage: update-gist.sh <gist_id> <entry_file> [date]}"
ENTRY_FILE="${2:?Usage: update-gist.sh <gist_id> <entry_file> [date]}"
TARGET_DATE="${3:-$(date +%Y-%m-%d)}"

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not found" >&2
  exit 1
fi

DAY_FILE="${TARGET_DATE}.md"

TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

cp "${ENTRY_FILE}" "${TMPDIR}/${DAY_FILE}"

# Update the gist
echo "Updating gist with ${DAY_FILE}..."
if gh gist view "${GIST_ID}" --filename "${DAY_FILE}" &>/dev/null; then
  # File exists, replace it
  gh gist edit "${GIST_ID}" --filename "${DAY_FILE}" - < "${TMPDIR}/${DAY_FILE}"
else
  # New file
  gh gist edit "${GIST_ID}" --add "${TMPDIR}/${DAY_FILE}"
fi

GIST_URL="https://gist.github.com/${GIST_ID}"
echo ""
echo "Updated: ${GIST_URL}"
echo "File: ${DAY_FILE}"
