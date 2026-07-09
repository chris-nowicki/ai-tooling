#!/usr/bin/env bash
# gather-calendar.sh
# Pulls today's calendar events from a Google Calendar ICS feed.
# Outputs structured markdown to stdout.
#
# Usage: ./gather-calendar.sh <ics_url> [date]
#   ics_url: the secret ICS URL from Google Calendar settings
#            (Calendar Settings > "Secret address in iCal format")
#   date: defaults to today (YYYY-MM-DD)
#
# No GCP project, OAuth, or API keys required. Just the private ICS URL.
#
# To get your ICS URL:
#   1. Go to Google Calendar > Settings
#   2. Click on your "Chancellor Clark" calendar
#   3. Scroll to "Secret address in iCal format"
#   4. Copy the URL (looks like: https://calendar.google.com/calendar/ical/...@group.calendar.google.com/private-.../basic.ics)
#   5. Paste it into the daily-log config as "calendar_ics_url"

set -euo pipefail

ICS_URL="${1:?Usage: gather-calendar.sh <ics_url> [date]}"
TARGET_DATE="${2:-$(date +%Y-%m-%d)}"

if ! command -v curl &>/dev/null; then
  echo "**Calendar unavailable** - curl not found."
  exit 0
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

# Fetch the ICS feed
if ! curl -sS -f -o "${TMPDIR}/calendar.ics" "${ICS_URL}" 2>"${TMPDIR}/curl_err"; then
  echo "**Calendar unavailable** - Failed to fetch ICS feed. Check your calendar_ics_url in config."
  echo "Error: $(cat "${TMPDIR}/curl_err")"
  exit 0
fi

echo "### Calendar for ${TARGET_DATE}"
echo ""
echo "| Time | Event | Duration |"
echo "|------|-------|----------|"

# Parse ICS and extract events for target date
# ICS format uses DTSTART/DTEND and SUMMARY fields
# This is a lightweight parser that handles the common cases
awk -v target="$TARGET_DATE" '
BEGIN {
  # Remove dashes from target date for comparison with ICS format (YYYYMMDD)
  gsub(/-/, "", target)
  event_count = 0
}

/^BEGIN:VEVENT/ {
  in_event = 1
  summary = ""
  dtstart = ""
  dtend = ""
  all_day = 0
  next
}

/^END:VEVENT/ {
  if (in_event && match_date) {
    event_count++

    if (all_day) {
      printf "| All day | %s | - |\n", summary
    } else {
      # Format times from HHMMSS to HH:MM
      start_fmt = substr(start_time, 1, 2) ":" substr(start_time, 3, 2)
      end_fmt = substr(end_time, 1, 2) ":" substr(end_time, 3, 2)

      # Calculate duration in minutes
      start_mins = substr(start_time, 1, 2) * 60 + substr(start_time, 3, 2)
      end_mins = substr(end_time, 1, 2) * 60 + substr(end_time, 3, 2)
      dur_mins = end_mins - start_mins
      if (dur_mins < 0) dur_mins += 1440  # handle midnight crossing

      if (dur_mins >= 60) {
        hours = int(dur_mins / 60)
        mins = dur_mins % 60
        if (mins > 0)
          duration = hours "h " mins "m"
        else
          duration = hours "h"
      } else {
        duration = dur_mins "m"
      }

      printf "| %s - %s | %s | %s |\n", start_fmt, end_fmt, summary, duration
    }
  }
  in_event = 0
  match_date = 0
  next
}

in_event && /^SUMMARY/ {
  sub(/^SUMMARY:/, "")
  gsub(/\\,/, ",")
  gsub(/\\;/, ";")
  # Handle line continuations (lines starting with space/tab)
  summary = $0
  next
}

# Handle line continuations for summary
in_event && summary != "" && /^ / {
  line = $0
  sub(/^ /, "", line)
  summary = summary line
  next
}

in_event && /^DTSTART/ {
  dtstart = $0
  # All-day events use VALUE=DATE (no time component)
  if (dtstart ~ /VALUE=DATE:/) {
    sub(/.*VALUE=DATE:/, "", dtstart)
    if (substr(dtstart, 1, 8) == target) {
      match_date = 1
      all_day = 1
    }
  } else {
    # Timed events: DTSTART:YYYYMMDDTHHMMSS or DTSTART;TZID=...:YYYYMMDDTHHMMSS
    sub(/.*:/, "", dtstart)
    if (substr(dtstart, 1, 8) == target) {
      match_date = 1
      all_day = 0
      start_time = substr(dtstart, 10, 6)
    }
  }
  next
}

in_event && /^DTEND/ {
  dtend = $0
  if (dtend ~ /VALUE=DATE:/) {
    sub(/.*VALUE=DATE:/, "", dtend)
  } else {
    sub(/.*:/, "", dtend)
    end_time = substr(dtend, 10, 6)
  }
  next
}

END {
  if (event_count == 0) {
    printf "| - | No events found | - |\n"
  }
  # Print total to stderr so we can capture it separately
  printf "%d\n", event_count > "/dev/stderr"
}
' "${TMPDIR}/calendar.ics" 2>"${TMPDIR}/count"

echo ""

event_count=$(cat "${TMPDIR}/count" 2>/dev/null || echo "0")
echo "**Total events:** ${event_count}"
echo ""

# Calculate total meeting time
# Re-parse to sum durations
total_mins=$(awk -v target="$TARGET_DATE" '
BEGIN {
  gsub(/-/, "", target)
  total = 0
}
/^BEGIN:VEVENT/ { in_event = 1; dtstart = ""; dtend = ""; match_date = 0; all_day = 0 }
/^END:VEVENT/ {
  if (in_event && match_date && !all_day) {
    start_mins = substr(start_time, 1, 2) * 60 + substr(start_time, 3, 2)
    end_mins = substr(end_time, 1, 2) * 60 + substr(end_time, 3, 2)
    dur = end_mins - start_mins
    if (dur < 0) dur += 1440
    total += dur
  }
  in_event = 0
}
in_event && /^DTSTART/ {
  line = $0
  if (line ~ /VALUE=DATE:/) {
    sub(/.*VALUE=DATE:/, "", line)
    if (substr(line, 1, 8) == target) { match_date = 1; all_day = 1 }
  } else {
    sub(/.*:/, "", line)
    if (substr(line, 1, 8) == target) { match_date = 1; start_time = substr(line, 10, 6) }
  }
}
in_event && /^DTEND/ {
  line = $0
  if (line !~ /VALUE=DATE:/) {
    sub(/.*:/, "", line)
    end_time = substr(line, 10, 6)
  }
}
END { print total }
' "${TMPDIR}/calendar.ics")

if [ "$total_mins" -gt 0 ]; then
  hours=$((total_mins / 60))
  mins=$((total_mins % 60))
  if [ "$mins" -gt 0 ]; then
    echo "**Total meeting time:** ${hours}h ${mins}m"
  else
    echo "**Total meeting time:** ${hours}h"
  fi
else
  echo "**Total meeting time:** 0h"
fi
echo ""
