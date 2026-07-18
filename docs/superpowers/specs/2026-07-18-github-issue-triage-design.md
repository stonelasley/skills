# github-triage plugin — Design

**Date:** 2026-07-18
**Status:** Approved

## Purpose

A skill that finds GitHub issues filed on the current repository within a recent
time window (24h by default) and returns a triaged list rating each issue's
readiness for an agent to implement.

## Location

New plugin `plugins/github-triage/` in the `st1-skills` marketplace, installable
independently of `starter`. Contains one skill: `triage-issues`.

```
plugins/github-triage/
├── .claude-plugin/
│   └── plugin.json
├── scripts/
│   └── fetch-issues.sh          # gh CLI fallback path
└── skills/
    └── triage-issues/
        └── SKILL.md
```

## Architecture

Deterministic data gathering is scripted; readiness assessment is model judgment.
The seam is deliberate — fetching is mechanical and worth making reliable, while
"is this specified well enough to act on" cannot be regexed without producing
confident nonsense.

### Data source selection

1. Prefer the GitHub MCP. Check for `mcp__github__search_issues` via ToolSearch.
2. If unavailable, fall back to `scripts/fetch-issues.sh` (gh CLI).

Both paths yield the same fields, so the assessment step is source-agnostic.

### Repository detection

`gh repo view --json nameWithOwner` resolves the repo from the current
directory's git remotes. Preferred over parsing `git remote get-url origin`
because it handles forks and non-`origin` remote names correctly.

### Fetching

Query issues **created** in the window — not updated.

- **MCP path:** `search_issues` with query
  `repo:<owner>/<name> is:issue is:open created:>=<cutoff>`.
  `search_issues` is already scoped to `is:issue`, so pull requests are excluded.
- **CLI path:** `gh issue list --search "created:>=<cutoff> is:open"` with
  `--json number,title,body,author,labels,createdAt,url,comments`.

`list_issues` is explicitly NOT used: its `since` parameter filters on updated
time, which would surface old issues with recent comments.

Cutoff is computed as an ISO 8601 UTC timestamp. Default window 24 hours;
overridden when the user states one ("last 3 days").

Issue bodies are truncated to ~2000 characters before assessment to bound
context on repos with long templated issues.

### Readiness assessment

Each issue is judged against three criteria:

1. **Clear acceptance criteria** — states what "done" looks like, testably.
2. **Reproduction steps** — for bugs: concrete steps, expected vs actual.
   Not applicable to feature requests; absence is not counted against them.
3. **Self-contained scope** — no unresolved design decisions, external
   blockers, or open debate in the comment thread.

Verdict is one of three tiers:

- **Ready** — an agent could start now.
- **Needs clarification** — plus the specific question that would unblock it.
- **Not agent-suitable** — plus why (design decision required, external
  dependency, or too vague to act on).

### Output

Terminal markdown only. Nothing written to disk, nothing posted to GitHub.
Grouped by verdict, Ready first. Per issue: number, title, one-line summary,
and for non-ready issues the concrete gap. Closes with a count per tier.

## Error handling

Each condition reports plainly and stops rather than guessing:

- Not a git repository.
- No GitHub remote (`gh repo view` fails).
- `gh` not installed, and no MCP available.
- `gh` installed but not authenticated.
- Zero issues in the window — say so; do not pad with older issues.

## Testing

1. `stonelasley/skills` has no issues, so exercise against a public repo with
   real traffic (e.g. `cli/cli`) using an explicit repo override.
2. Verify the MCP path returns issues created in-window.
3. Verify the CLI script independently returns the same issue numbers.
4. Verify a zero-result window reports emptiness rather than fabricating.

## Known constraints

- The MCP is authenticated with a token from `gh auth token`, stored as an
  Authorization header in user MCP config. If `gh auth refresh` or re-login
  rotates that token, the MCP will 401 and the `add-json` command must be
  re-run. Noted in the skill's troubleshooting section.

## Out of scope (YAGNI)

- Writing labels or comments back to GitHub.
- Persisting reports to disk.
- Closed issues, pull requests, cross-repo triage.
