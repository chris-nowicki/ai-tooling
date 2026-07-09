---
name: daily-log
description: Generate a structured daily work log by pulling Google Calendar events, GitHub activity, and optional manual context, then appending it to a running GitHub Gist. Use this skill whenever the user says things like "log my day", "daily log", "what did I do today", "end of day summary", "update my work log", "time log", "activity log", or any variation of wanting to record or review their daily work activities. Also trigger when the user mentions their gist-based log, wants to review their week, or asks about time spent on different work categories.
---

# Daily Log Skill

Generate a structured end-of-day work log by pulling Google Calendar events, GitHub activity, and optional manual context (micro-log notes, ad-hoc input), then appending the result to a running GitHub Gist.

## Prerequisites

- `gh` CLI authenticated (used for GitHub activity and Gist management)
- A GitHub Gist to use as the log store (the skill will create one if needed)
- For calendar: one of the following (in priority order):
  1. Google Calendar MCP connected in Claude Code (preferred, zero setup)
  2. Private ICS URL from Google Calendar (no GCP project needed, just a URL from calendar settings)

## Configuration

The skill looks for a config file at `~/.config/daily-log/config.json`. If it doesn't exist, the skill will prompt the user to set it up on first run.

```json
{
  "gist_id": "your-gist-id-here",
  "github_username": "your-username",
  "github_orgs": ["bigcommerce", "other-org"],
  "calendar_name": "Chancellor Clark",
  "calendar_ics_url": "",
  "micro_log_path": "~/.config/daily-log/micro-log.md",
  "default_categories": [
    "deep-work",
    "meetings",
    "cross-team",
    "planning",
    "reactive-comms",
    "code-review",
    "ops-oncall"
  ]
}
```

## Workflow

### Step 1: Load config

Read `~/.config/daily-log/config.json`. If it doesn't exist, run the setup flow:

1. Ask the user for their GitHub username
2. Ask for their GitHub org(s) (comma-separated if multiple, to filter out personal repo activity)
3. Ask for the Google Calendar name to pull events from (e.g. "Chancellor Clark")
4. Create a new Gist with `gh gist create` using a starter markdown file
5. Ask if they have custom categories or if the defaults are fine
6. Write the config file

### Step 2: Gather calendar events

Pull today's events from the configured calendar. Only pull from the specific calendar named in `calendar_name` in the config. Ignore other calendars (shared calendars, holiday calendars, etc.).

**Option A: Google Calendar MCP (preferred)**

If the Google Calendar MCP is connected, use it to list today's events. Filter the results to only include events from the calendar matching the configured `calendar_name`. For each event, capture:

- Start time and end time
- Event title
- Duration (calculated from start/end)

**Option B: ICS URL fallback**

If the MCP is not available, run `scripts/gather-calendar.sh` with the `calendar_ics_url` from config. This fetches the private ICS feed directly from Google Calendar using `curl` and parses today's events. No GCP project, OAuth, or API keys needed.

To get the ICS URL (one-time setup during config):
1. Go to Google Calendar > Settings
2. Click on the "Chancellor Clark" calendar
3. Scroll to "Secret address in iCal format"
4. Copy the URL and save it as `calendar_ics_url` in config

**Option C: Manual fallback**

If neither is available, ask the user: "I couldn't pull your calendar automatically. Can you give me a quick rundown of your meetings today?" This keeps the flow moving even without tooling.

Output the events as a markdown table:

```
| Time | Event | Duration |
|------|-------|----------|
| 9:00 - 9:15 | Standup | 15m |
| 10:00 - 10:30 | 1:1 with manager | 30m |
| 14:00 - 15:00 | Native Hosting retro | 1h |
```

Include a total meeting time at the bottom (e.g. "**Total meeting time:** 1h 45m"). This total feeds directly into the time breakdown in Step 6.

### Step 3: Gather GitHub activity

Run the script at `scripts/gather-github-activity.sh` which takes the username and a comma-separated list of orgs as arguments, pulling only activity from those orgs:

- PRs created or merged today in any of the configured orgs
- PRs reviewed today in any of the configured orgs (via GitHub events API for accurate date matching)
- Issues created today in any of the configured orgs
- Commits pushed today in any of the configured orgs

The script uses `--created` and `--merged` date filters instead of `--updated` to avoid pulling in stale PRs that just got a CI run or a comment. The `--owner` flag scopes all search queries to the configured orgs, so personal repos never show up. Results from all orgs are combined and deduplicated.

The script outputs structured markdown. If `gh` is not available or not authenticated, skip this step gracefully and note it in the log.

### Step 4: Check for micro-log entries

Read the micro-log file (default `~/.config/daily-log/micro-log.md`). This file contains timestamped quick notes the user captured throughout the day via Raycast or manual entry. Format:

```
## 2026-03-11
- 09:15 | Debugged R2 credential rotation in Puppet
- 10:30 | Slack thread with platform team about deploy pipeline
- 14:00 | Helped Roman with Terraform state migration
```

Entries are just timestamps and descriptions. Categories are assigned by you during log generation (see Step 4).

If the file has entries for today, incorporate them. If not, that's fine, just note that no micro-log entries were found.

### Step 5: Auto-categorize and fill gaps

First, categorize each micro-log entry using the configured categories. Use context clues from the description:

- Mentions of Slack, email, DMs, threads -> `reactive-comms`
- Mentions of specific teammates from other teams, helping other teams -> `cross-team`
- Mentions of PRs, code review, reviewing -> `code-review`
- Mentions of standup, 1:1, retro, sync, meeting -> `meetings`
- Mentions of roadmap, sprint, planning, priorities, docs -> `planning`
- Mentions of oncall, pages, incidents, alerts -> `ops-oncall`
- Building, fixing, debugging, shipping, coding -> `deep-work`

When in doubt, pick the closest match. If an entry could go either way, prefer the more specific category.

Then present the categorized entries along with GitHub activity to the user and ask:

- "Anything else worth noting that isn't captured above?"
- "Any recategorization needed?"

Keep this lightweight. The user should be able to say "looks good" and move on, or add a quick note or two.

### Step 6: Generate the daily log entry

Structure the entry as follows:

```markdown
## {Day of week}, {Month} {Day}, {Year}

### Summary
{One or two sentence overview of the day}

### Time Breakdown
| Category | Approx Hours | Details |
|----------|-------------|---------|
| deep-work | 3h | Puppet R2 creds, CLI bundling fix |
| meetings | 2h | Standup, 1:1 with manager, retro |
| cross-team | 1.5h | Terraform state migration with Roman |
| reactive-comms | 1h | Slack threads, email triage |
| code-review | 0.5h | PR #432, PR #418 |

### Calendar
| Time | Event | Duration |
|------|-------|----------|
| 9:00 - 9:15 | Standup | 15m |
| 10:00 - 10:30 | 1:1 with manager | 30m |
| 14:00 - 15:00 | Native Hosting retro | 1h |

**Total meeting time:** 1h 45m

### GitHub Activity
- **Reviews:** 3 PRs reviewed
  - [bigcommerce/ignition#206](https://github.com/bigcommerce/ignition/pull/206) - Routing gRPC service for shared KV namespace
  - [bigcommerce/docs#1275](https://github.com/bigcommerce/docs/pull/1275) - Catalyst 1.5.0 release notes
  - [bigcommerce/store-control-panel#4008](https://github.com/bigcommerce/store-control-panel/pull/4008) - Chat history session implementation
- **PRs:** 2 created/merged
  - [bigcommerce/ignition#445](https://github.com/bigcommerce/ignition/pull/445) - bcli log-tail (opened)
  - [bigcommerce/ignition#432](https://github.com/bigcommerce/ignition/pull/432) - R2 rotation (merged)
- **Commits:** 4 commits across 2 repos
  - [bigcommerce/ignition](https://github.com/bigcommerce/ignition) - 3 commits
  - [bigcommerce/interfaces](https://github.com/bigcommerce/interfaces) - 1 commit

### Notes
{Any additional context, blockers, or things to follow up on tomorrow}
```

The time breakdown should be estimated. Use calendar events as the ground truth for meeting time, then use GitHub timestamps and micro-log entries to fill in the rest. Be transparent when estimating. The user can adjust.

### Step 7: Append to the Gist

Use the approach in `scripts/update-gist.sh` to:

1. Determine the current week's filename (format: `YYYY-WXX.md`, e.g., `2026-W11.md`)
2. Check if that file already exists in the Gist
3. If yes, append today's entry to it
4. If no, create the file with a week header and today's entry

The week file starts with:

```markdown
# Week {week_number} - {Month} {start_day}-{end_day}, {Year}
```

### Step 8: Confirm and share link

After updating the Gist, confirm success and share the Gist URL so the user can review.

## Tone and style

- Keep the log entries concise and scannable
- Use the user's actual project names and teammate names when available from context
- Don't over-explain or pad entries
- The log is a personal tool, not a formal report. Keep it real.

## Error handling

- If `gh` is not installed or not authenticated, tell the user how to set it up (`gh auth login`)
- If the Gist doesn't exist or the ID is wrong, offer to create a new one
- If the micro-log file doesn't exist, skip it silently (it's optional)
- If GitHub API calls fail, still generate the log from whatever data is available and let the user paste it manually
