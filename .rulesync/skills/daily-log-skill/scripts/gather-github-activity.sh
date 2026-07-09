#!/usr/bin/env bash
# gather-github-activity.sh
# Pulls today's GitHub activity for the configured user.
# Outputs structured markdown to stdout.
#
# Usage: ./gather-github-activity.sh <github_username> <orgs> [date]
#   orgs: comma-separated list of GitHub orgs (e.g. "bigcommerce,bigcommerce-labs")
#   date defaults to today (YYYY-MM-DD)

set -euo pipefail

USERNAME="${1:?Usage: gather-github-activity.sh <username> <orgs> [date]}"
ORGS="${2:?Usage: gather-github-activity.sh <username> <orgs> [date]}"
TARGET_DATE="${3:-$(date +%Y-%m-%d)}"

# Build --owner flags from comma-separated orgs
OWNER_FLAGS=()
IFS=',' read -ra ORG_ARRAY <<< "$ORGS"
for org in "${ORG_ARRAY[@]}"; do
  OWNER_FLAGS+=(--owner "$org")
done

# Check gh is available
if ! command -v gh &>/dev/null; then
  echo "**GitHub activity unavailable** - \`gh\` CLI not found. Install it and run \`gh auth login\`."
  exit 0
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo "**GitHub activity unavailable** - \`gh\` CLI not authenticated. Run \`gh auth login\`."
  exit 0
fi

echo "### GitHub Activity for ${ORGS} (${TARGET_DATE})"
echo ""

# --- PRs authored (created or merged today) ---
echo "#### Pull Requests"
# Search for PRs created today
created_prs=$(gh search prs --author="${USERNAME}" --created="${TARGET_DATE}..${TARGET_DATE}" "${OWNER_FLAGS[@]}" --json repository,title,number,state,url --limit 50 2>/dev/null || echo "[]")
# Search for PRs merged today
merged_prs=$(gh search prs --author="${USERNAME}" --merged="${TARGET_DATE}..${TARGET_DATE}" "${OWNER_FLAGS[@]}" --json repository,title,number,state,url --limit 50 2>/dev/null || echo "[]")
# Combine and deduplicate by URL
prs=$(echo "[$created_prs, $merged_prs]" | jq -s '[.[][] | .[]?] | unique_by(.url)' 2>/dev/null || echo "[]")

if [ "$prs" = "[]" ] || [ -z "$prs" ]; then
  echo "- No PR activity found"
else
  echo "$prs" | jq -r '.[] | "- [\(.repository.nameWithOwner)#\(.number)](\(.url)) - \(.title) (\(.state))"'
fi
echo ""

# --- PRs reviewed today (using events API for accurate timestamps) ---
echo "#### Reviews"
# Build a jq filter to match configured orgs
ORG_FILTER=$(printf '%s\n' "${ORG_ARRAY[@]}" | jq -R . | jq -s 'join("|")')
# Get unique repo#number pairs from review events today
review_keys=$(gh api "/users/${USERNAME}/events" --paginate --jq "[.[] | select(.type == \"PullRequestReviewEvent\" and (.created_at | startswith(\"${TARGET_DATE}\")) and (.repo.name | test(${ORG_FILTER}))) | {repo: .repo.name, number: .payload.pull_request.number}] | unique_by(\"\(.repo)#\(.number)\")" 2>/dev/null || echo "[]")

if [ "$review_keys" = "[]" ] || [ -z "$review_keys" ]; then
  echo "- No reviews found"
else
  # Fetch title for each reviewed PR
  echo "$review_keys" | jq -c '.[]' | while read -r item; do
    repo=$(echo "$item" | jq -r '.repo')
    number=$(echo "$item" | jq -r '.number')
    title=$(gh api "/repos/${repo}/pulls/${number}" --jq '.title' 2>/dev/null || echo "unknown")
    echo "- [${repo}#${number}](https://github.com/${repo}/pull/${number}) - ${title}"
  done
fi
echo ""

# --- Issues ---
echo "#### Issues"
issues=$(gh search issues --author="${USERNAME}" --created="${TARGET_DATE}..${TARGET_DATE}" "${OWNER_FLAGS[@]}" --json repository,title,number,state,url --limit 50 2>/dev/null || echo "[]")

if [ "$issues" = "[]" ] || [ -z "$issues" ]; then
  echo "- No issue activity found"
else
  echo "$issues" | jq -r '.[] | "- [\(.repository.nameWithOwner)#\(.number)](\(.url)) - \(.title) (\(.state))"'
fi
echo ""

# --- Commits (using gh search commits for private repo support) ---
echo "#### Commits"

# Collect PR-associated repo#number pairs for dedup (from earlier PR results)
pr_repos=""
if [ "$prs" != "[]" ] && [ -n "$prs" ]; then
  pr_repos=$(echo "$prs" | jq -r '.[].repository.nameWithOwner' 2>/dev/null || echo "")
fi

# Search commits authored today across configured orgs
all_commits="[]"
for org in "${ORG_ARRAY[@]}"; do
  org_commits=$(gh search commits --author="${USERNAME}" --author-date="${TARGET_DATE}..${TARGET_DATE}" --owner="${org}" --json repository,sha,commit --limit 50 2>/dev/null || echo "[]")
  all_commits=$(echo "[$all_commits, $org_commits]" | jq -s '[.[][] | .[]?]' 2>/dev/null || echo "[]")
done

# Deduplicate by SHA
all_commits=$(echo "$all_commits" | jq 'unique_by(.sha)' 2>/dev/null || echo "[]")

if [ "$all_commits" = "[]" ] || [ -z "$all_commits" ]; then
  echo "- No commits found"
else
  echo "$all_commits" | jq -r '.[] | "- [\(.repository.fullName)](https://github.com/\(.repository.fullName)/commit/\(.sha[0:7])) - \(.commit.message | split("\n")[0])"' | head -20
fi
echo ""
