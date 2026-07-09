---
name: brag
description: >
  Maintain a Brag Doc — a private record of work impact, achievements, and evidence
  of value stored as a GitHub Gist. Use when the user says "/brag", "brag", "add to
  brag doc", or asks to record an accomplishment.
disable-model-invocation: true
---

# Brag Doc

## Configuration

| Setting | Value |
|---------|-------|
| Gist ID | `b9ba0ec88b7d276b8d6923e165f9c7ef` |
| Filename | `brag-doc.md` |

**Setup guard**: If the Gist ID above is a placeholder or empty, stop and tell the user to create a secret gist and update this table.

---

## Gist Operations

**Read:**
```bash
gh gist view b9ba0ec88b7d276b8d6923e165f9c7ef -f brag-doc.md --raw
```

**Write** (always write full doc — gist API does not support partial updates):
1. Write the complete updated doc to `/tmp/brag-doc.md`
2. Push:
```bash
jq -Rs '{"files":{"brag-doc.md":{"content":.}}}' /tmp/brag-doc.md | gh api --method PATCH /gists/<YOUR_GIST_ID> --input -
```

---

## Mode Detection

| Input | Mode |
|-------|------|
| `/brag` (no args) | **Add** — infer accomplishment from conversation context |
| `/brag <text>` | **Add** — use provided text as the basis |
| `/brag review` | **Review** — fetch and display full doc |

---

## Add Mode

1. Load `references/entry-guidelines.md` (relative to this skill).
2. Identify the accomplishment from session context or provided text.
3. Auto-assess depth: use **quick format** for straightforward wins, **detailed format** for high-impact or complex work. Default to quick unless the impact clearly warrants detail.
4. Determine the current quarter from today's date.
5. Draft the entry and present it to the user for review. Do not write to the gist until approved.
6. Ask: is this **completed** (insert in the current quarter section) or **in progress** (insert in the "In Progress" section)?
7. On approval:
   a. Fetch current gist content (guard against stale state).
   b. Insert the entry at the correct position — newest first within the target section.
   c. Auto-create missing year/quarter headings if needed.
   d. Write the full updated doc to `/tmp/brag-doc.md`.
   e. Push to gist using the write operation above.
   f. Confirm success and print the gist URL: `https://gist.github.com/<YOUR_GIST_ID>`

---

## Review Mode

1. Fetch and display the full brag doc.
2. Wait for user direction — possible actions:
   - Reorganize entries
   - Merge related entries
   - Promote in-progress items to completed
   - Edit existing entries (add evidence, refine wording)
   - Add new entries
3. Present proposed changes for approval before writing.
4. On approval: re-fetch the gist (guard against stale state), apply edits, write to `/tmp/brag-doc.md`, push to gist.

---

## Structural Rules

Maintain this document structure at all times:

```
# Brag Doc

## 2026              ← Year headings: newest first
### Q1 (Jan – Mar)   ← Quarter headings: newest first within year
[entries]            ← Entries: newest first within quarter

---

## In Progress
[entries]
```

- Always preserve `# Brag Doc` as the document header.
- Year headings (`## YYYY`) — newest year first.
- Quarter headings (`### Q1 (Jan – Mar)`, `### Q2 (Apr – Jun)`, `### Q3 (Jul – Sep)`, `### Q4 (Oct – Dec)`) — newest first within year.
- Entries within a section — newest first.
- Horizontal rule (`---`) separates the last yearly section from `## In Progress`.
- Auto-create missing year or quarter headings when inserting an entry. Use the quarter format shown above.
