#!/usr/bin/env bash
# setup.sh
# Interactive setup for the daily-log skill.
# Creates config at ~/.config/daily-log/config.json
# Optionally creates a new GitHub Gist for log storage.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/daily-log"
CONFIG_FILE="${CONFIG_DIR}/config.json"
MICRO_LOG_PATH="${CONFIG_DIR}/micro-log.md"

echo "=== Daily Log Setup ==="
echo ""

# Check gh CLI
if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is required. Install from https://cli.github.com/"
  exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo "Error: gh CLI is not authenticated. Run: gh auth login"
  exit 1
fi

mkdir -p "${CONFIG_DIR}"

# GitHub username
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
if [ -z "${GITHUB_USER}" ]; then
  read -rp "GitHub username: " GITHUB_USER
else
  echo "Detected GitHub user: ${GITHUB_USER}"
  read -rp "Use this? [Y/n] " confirm
  if [[ "${confirm}" =~ ^[Nn] ]]; then
    read -rp "GitHub username: " GITHUB_USER
  fi
fi

# GitHub orgs (to scope activity and filter out personal repos)
echo ""
echo "GitHub org(s) to filter activity by (comma-separated if multiple)"
read -rp "Orgs (e.g. bigcommerce,other-org): " GITHUB_ORGS_RAW
# Convert to JSON array
GITHUB_ORGS=$(echo "${GITHUB_ORGS_RAW}" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')

# Google Calendar name
echo ""
echo "Which Google Calendar should the log pull events from?"
echo "(This is the calendar name as it appears in Google Calendar, e.g. your name)"
read -rp "Calendar name: " CALENDAR_NAME

# Calendar ICS URL (optional, used as fallback when MCP isn't available)
echo ""
echo "Optional: Private ICS URL for calendar fallback (no GCP project needed)."
echo "To find it: Google Calendar > Settings > your calendar > 'Secret address in iCal format'"
echo "Press Enter to skip (you can add it to the config later)."
read -rp "ICS URL: " CALENDAR_ICS_URL

# Gist setup
read -rp "Do you have an existing Gist ID to use? [y/N] " has_gist
if [[ "${has_gist}" =~ ^[Yy] ]]; then
  read -rp "Gist ID: " GIST_ID
  # Verify it exists
  if ! gh gist view "${GIST_ID}" &>/dev/null; then
    echo "Warning: Could not access gist ${GIST_ID}. Proceeding anyway."
  fi
else
  echo "Creating a new Gist for your daily logs..."
  TMPFILE=$(mktemp)
  echo "# Daily Work Log" > "${TMPFILE}"
  echo "" >> "${TMPFILE}"
  echo "Auto-generated daily work logs." >> "${TMPFILE}"
  
  GIST_URL=$(gh gist create "${TMPFILE}" --desc "Daily Work Log" --public 2>&1 | tail -1)
  GIST_ID=$(echo "${GIST_URL}" | grep -oP '[a-f0-9]{20,}' || echo "${GIST_URL##*/}")
  rm -f "${TMPFILE}"
  
  echo "Created gist: ${GIST_URL}"
  echo "Gist ID: ${GIST_ID}"
fi

# Categories
DEFAULT_CATS='["deep-work","meetings","cross-team","planning","reactive-comms","code-review","ops-oncall"]'
echo ""
echo "Default work categories:"
echo "  deep-work, meetings, cross-team, planning, reactive-comms, code-review, ops-oncall"
read -rp "Use defaults? [Y/n] " use_defaults
if [[ "${use_defaults}" =~ ^[Nn] ]]; then
  echo "Enter categories as comma-separated values:"
  read -rp "> " custom_cats
  CATEGORIES=$(echo "${custom_cats}" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
else
  CATEGORIES="${DEFAULT_CATS}"
fi

# Create micro-log file if it doesn't exist
if [ ! -f "${MICRO_LOG_PATH}" ]; then
  touch "${MICRO_LOG_PATH}"
  echo "Created micro-log file at ${MICRO_LOG_PATH}"
fi

# Write config
cat > "${CONFIG_FILE}" <<EOF
{
  "gist_id": "${GIST_ID}",
  "github_username": "${GITHUB_USER}",
  "github_orgs": ${GITHUB_ORGS},
  "calendar_name": "${CALENDAR_NAME}",
  "calendar_ics_url": "${CALENDAR_ICS_URL}",
  "micro_log_path": "${MICRO_LOG_PATH}",
  "default_categories": ${CATEGORIES}
}
EOF

echo ""
echo "Config written to ${CONFIG_FILE}"
echo ""
echo "Setup complete! You can now use the daily-log skill."
echo ""
echo "Optional: Set up a Raycast script command to quickly add micro-log entries."
echo "The micro-log file is at: ${MICRO_LOG_PATH}"
echo "Format: - HH:MM | category | description"
