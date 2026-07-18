---
name: triage-issues
description: Use when the user asks to triage, review, or check recent GitHub issues on the current repository - fetches issues filed in a recent window (24h by default) and rates each one's readiness for an agent to implement. Triggers on "triage issues", "what issues came in", "new issues today", "any new bugs filed", "check the issue queue".
---

# Triage Recent GitHub Issues

Find issues filed on the current repository within a recent window and report
which ones an agent could actually pick up.

## 1. Determine the window

Default to **24 hours**. If the user states a window ("last 3 days", "this
week"), use that instead. Compute an ISO 8601 UTC cutoff:

```bash
date -u -d "24 hours ago" +%Y-%m-%dT%H:%M:%SZ
```

## 2. Resolve the repository

```bash
gh repo view --json nameWithOwner --jq .nameWithOwner
```

This reads the current directory's git remotes and handles forks and
non-`origin` remote names. If the user names a different repo, use theirs.

## 3. Fetch the issues

**Prefer the GitHub MCP.** If `mcp__github__search_issues` is available:

```
search_issues(
  query: "repo:<owner>/<name> is:issue is:open created:>=<cutoff>",
  sort: "created", order: "desc", perPage: 10
)
```

Keep `perPage` at 10 or below — each result carries the full body plus user and
reaction objects, so large pages flood context. Paginate if needed.

**Otherwise fall back to the CLI script:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/fetch-issues.sh <hours> [owner/repo]
```

Both paths return the same issues. Use `created:>=`, never `list_issues` with
`since` — that parameter filters on *updated* time and will surface months-old
issues that merely got a new comment.

For issues whose readiness hinges on discussion, read the comment thread with
`issue_read` (or `gh issue view <n> --comments`). Don't pull threads you don't
need.

## 4. Assess readiness

Judge each issue against three criteria:

**Clear acceptance criteria** — does it state what "done" looks like, in a way
you could verify? "Make search faster" does not qualify; "search should return
in under 200ms for 10k records" does.

**Reproduction steps** — for bugs: concrete steps, expected vs actual behavior,
relevant environment. Feature requests have no repro by nature; do not count
its absence against them.

**Self-contained scope** — no unresolved design decision, no external blocker,
no live debate in the thread. An issue where maintainers are still arguing about
the approach is not ready no matter how well written it is.

Assign exactly one verdict:

| Verdict | Meaning |
|---|---|
| **Ready** | An agent could start now without asking anything. |
| **Needs clarification** | One or two specific unknowns block it. State the exact question. |
| **Not agent-suitable** | Requires a design decision, has an external dependency, or is too vague to act on. State which. |

Be honest here. A triage list that marks everything Ready is worthless — the
value is in accurately separating what is actionable from what isn't. Judge the
issue as written, not as you imagine it could be rewritten.

## 5. Report

Terminal markdown. Group by verdict, Ready first, and close with counts.

```markdown
## Issue triage — <owner>/<repo>, last <window>

### Ready (2)
- **#123** Fix null deref in config loader
  Crashes when `config.yml` lacks a `timeout` key. Repro steps and stack
  trace included; fix location is obvious from the trace.

### Needs clarification (1)
- **#124** Add retry logic to the uploader
  Well scoped, but doesn't say how many retries or what backoff.
  **Ask:** what retry count and backoff strategy?

### Not agent-suitable (1)
- **#125** Rethink the plugin API
  Open design question with three competing proposals in the thread.

**4 issues filed in the last 24h** — 2 ready, 1 needs clarification,
1 not agent-suitable.
```

Do not write files or post anything to GitHub. This skill only reports.

## Error handling

Report the specific condition and stop. Do not work around it silently.

| Condition | Response |
|---|---|
| Not a git repository | Say so; ask which repo to triage. |
| No GitHub remote | Say the directory has no GitHub remote. |
| `gh` missing and no MCP | Report both are unavailable. |
| `gh` not authenticated | Tell the user to run `gh auth login`. |
| Zero issues in window | Say plainly that nothing was filed. Do not widen the window or pad with older issues to produce a fuller-looking report. |

## Troubleshooting

**MCP returns 401.** The GitHub MCP may be configured with a token from
`gh auth token`. Re-login or `gh auth refresh` rotates that token, leaving a
stale value in the MCP config. Re-run the install to refresh it:

```bash
claude mcp add-json github --scope user \
  "{\"type\":\"http\",\"url\":\"https://api.githubcopilot.com/mcp\",\"headers\":{\"Authorization\":\"Bearer $(gh auth token)\"}}"
```

The CLI fallback path keeps working regardless, since it authenticates through
`gh` directly.
