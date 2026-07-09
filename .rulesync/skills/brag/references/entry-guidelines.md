# Entry Guidelines

## What Makes a Good Entry

Impact > activity. Focus on outcomes, not tasks performed.

- **Quantify results** when possible (latency reduced by X%, unblocked Y teams, saved Z hours/week)
- **Include evidence** — link to PRs, tickets, Slack threads, docs, or metrics dashboards
- **Name the scope** — team-level, org-level, cross-org, customer-facing
- **Credit collaborators** where appropriate, but center your contribution

## Entry Formats

### Quick Entry (1–3 lines)

Use for straightforward wins where impact is clear without elaboration.

```markdown
**Migrated checkout flow to Server Components** *(Feb 2026)* — Reduced client bundle by 34KB, improving LCP by 400ms on the checkout page. [PR #1847](url)
```

### Detailed Entry (bullet list)

Use for high-impact, complex, or ambiguous work that benefits from context.

```markdown
**Led adoption of Streaming SSR across Catalyst storefronts** *(Jan–Feb 2026)*

- **Role**: Drove architecture decision and implementation as tech lead
- **Problem**: Full-page data fetching blocked render, causing 3s+ TTFB on category pages
- **Actions**: Designed Streamable data pattern, implemented Suspense boundaries, mentored 3 engineers on migration
- **Results**: TTFB reduced to <800ms, 95th percentile LCP improved 2.1s → 1.2s across all storefronts
- **Evidence**: [RFC](url), [PR #1623](url), [Datadog dashboard](url)
- **Visibility**: Presented approach at Frontend Guild; adopted by 2 other teams
```

### In-Progress Entry

Use for significant work underway that you want to track before completion.

```markdown
**[Implementing edge-side personalization for Catalyst]** *(Started Jan 2026)* — Expected to reduce personalization latency from ~200ms to <50ms by moving logic to Cloudflare Workers. [CATALYST-1892](url)
```

Conventions:
- Title wrapped in `[square brackets]` to signal work-in-progress
- Date uses `Started` prefix
- States expected impact, not actual results
- Promote to a completed entry (quick or detailed) once shipped

## Impact Framing

### Weak → Strong Examples

| Weak (activity) | Strong (impact) |
|------------------|-----------------|
| Updated dependencies | Resolved 3 critical CVEs in auth dependencies, eliminating security review blockers for SOC 2 audit |
| Fixed bug in cart | Fixed race condition causing duplicate charges — affected ~50 orders/week, resolved 2 open support escalations |
| Wrote tests | Added integration test suite for checkout flow, catching 4 regressions in the next 2 sprints before they reached production |
| Reviewed PRs | Provided architectural feedback on 12 PRs during Streaming SSR migration, unblocking 3 junior engineers and maintaining consistency across the codebase |
| Attended meetings | Facilitated cross-team alignment between Catalyst and Platform teams on API versioning strategy, resulting in shared contract adopted by both teams |

### Impact Categories to Consider

- **Performance**: Latency, bundle size, Core Web Vitals, throughput
- **Reliability**: Error rates, incident prevention, test coverage
- **Velocity**: Unblocking others, reducing cycle time, automation
- **Quality**: Code review, mentoring, architecture decisions
- **Business**: Revenue impact, customer satisfaction, cost savings
- **Scope/Leadership**: Cross-team coordination, RFCs, tech talks, hiring

## Date Formatting

| Scenario | Format |
|----------|--------|
| Single month | `*(Feb 2026)*` |
| Multi-month range | `*(Jan–Feb 2026)*` |
| Ongoing / in-progress | `*(Started Jan 2026)*` |
| Exact date (rare) | `*(Feb 14, 2026)*` |

Use en-dash (`–`) for ranges, not hyphen (`-`).
