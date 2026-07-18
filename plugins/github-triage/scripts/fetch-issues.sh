#!/usr/bin/env bash
# Fetch issues created in a recent window for the current directory's repo.
# Fallback path used when the GitHub MCP is unavailable.
#
# Usage: fetch-issues.sh [HOURS] [OWNER/REPO]
#   HOURS      lookback window, default 24
#   OWNER/REPO override repo detection
#
# Emits JSON array on stdout. Diagnostics go to stderr.

set -euo pipefail

HOURS="${1:-24}"
REPO_OVERRIDE="${2:-}"

die() { echo "error: $*" >&2; exit 1; }

case "$HOURS" in
  ''|*[!0-9]*) die "hours must be a positive integer, got: $HOURS" ;;
esac
[ "$HOURS" -gt 0 ] || die "hours must be greater than zero"

command -v gh >/dev/null 2>&1 \
  || die "gh CLI not installed. Install it or enable the GitHub MCP."

gh auth status >/dev/null 2>&1 \
  || die "gh is not authenticated. Run: gh auth login"

if [ -n "$REPO_OVERRIDE" ]; then
  REPO="$REPO_OVERRIDE"
else
  git rev-parse --git-dir >/dev/null 2>&1 \
    || die "not inside a git repository. cd into one or pass OWNER/REPO."
  # gh resolves the repo from git remotes, handling forks and non-origin names.
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" \
    || die "could not resolve a GitHub repository from this directory's remotes."
fi

# GNU date and BSD date disagree on relative-time flags; try both.
if CUTOFF="$(date -u -d "$HOURS hours ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
  :
elif CUTOFF="$(date -u -v-"${HOURS}"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
  :
else
  die "could not compute a cutoff timestamp with this system's date command."
fi

echo "repo=$REPO window=${HOURS}h cutoff=$CUTOFF" >&2

# --search with created:>= filters on filing time, not last activity.
# gh issue list excludes pull requests by default.
gh issue list \
  --repo "$REPO" \
  --search "created:>=$CUTOFF is:open" \
  --limit 100 \
  --json number,title,body,author,labels,createdAt,url,comments
