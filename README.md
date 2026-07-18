# st1-skills

A personal [Claude Code](https://claude.com/claude-code) plugin marketplace —
skills and slash commands, synced across machines via this repository.

## Install

Add the marketplace once per machine:

```
/plugin marketplace add stonelasley/skills
```

Then install the plugins you want:

```
/plugin install github-triage@st1-skills
/plugin install starter@st1-skills
```

To verify the install worked, run `/hello` (from `starter`).

Worth enabling auto-update while you're there — `/plugin` → Marketplaces →
`st1-skills` → Enable auto-update. It is off by default for third-party
marketplaces, so without it you pull every update by hand. See
[Updating](#updating).

## Plugins

### `github-triage`

Triages GitHub issues filed on the current repository within a recent window
(24h by default) and rates each one's readiness for an agent to implement:
**Ready**, **Needs clarification** (with the specific question), or **Not
agent-suitable** (with the reason).

Ask for it in your own words — "triage recent issues", "what issues came in
today", "any new bugs filed this week". Reports to the terminal only; never
writes files or posts to GitHub.

Prefers the [GitHub MCP](https://github.com/github/github-mcp-server) and falls
back to the `gh` CLI, so it works with either. For the MCP:

```bash
claude mcp add-json github --scope user \
  "{\"type\":\"http\",\"url\":\"https://api.githubcopilot.com/mcp\",\"headers\":{\"Authorization\":\"Bearer $(gh auth token)\"}}"
```

That reuses your existing `gh` token instead of a separate PAT — it needs
`repo` scope. Since `gh auth refresh` or re-login rotates that token, a 401
later means re-running the command above. The `gh` fallback is unaffected.

For the CLI path alone, just `gh auth login`.

### `starter`

Example plugin: one `/hello` command and one skill. Copy it as the template for
new plugins.

## Updating

Edit a plugin locally, commit, and push. What an installed user does next depends
on whether they have auto-update enabled for this marketplace.

**With auto-update on** — nothing. Claude Code refreshes in the background shortly
after startup and updates installed plugins on disk. The running session keeps the
old version until they relaunch or run `/reload-plugins`.

Auto-update is **off by default for third-party marketplaces** like this one. Users
turn it on via `/plugin` → Marketplaces tab → select `st1-skills` → Enable
auto-update.

**With auto-update off** — refreshing the catalog and updating the plugin are two
separate steps:

```
/plugin marketplace update st1-skills   # refresh the catalog (picks up NEW plugins)
/plugin update starter@st1-skills       # pull new content for an INSTALLED plugin
```

A brand-new plugin also needs `/plugin install <name>@st1-skills` after the
catalog refresh.

### Why plugin.json has no `version` field

Deliberate. If a plugin declares `"version": "1.0.0"`, Claude Code will not ship
new commits to existing users until that string changes — they keep the cached
copy. Omitting `version` makes the git commit SHA the version, so every pushed
commit is picked up automatically.

If you ever add a `version` field, you must bump it on **every** release. Also
don't set `version` in both `plugin.json` and the marketplace entry: `plugin.json`
wins silently, so a stale marketplace entry can mask the real version.

## Adding a new plugin

1. Copy `plugins/starter/` to `plugins/<new-name>/`.
2. Set `name` and `description` in its `.claude-plugin/plugin.json`. Leave
   `version` out — see [above](#why-pluginjson-has-no-version-field).
3. Add a matching entry to `.claude-plugin/marketplace.json` with a `source` of
   `./plugins/<new-name>`.
4. Add a section under [Plugins](#plugins) describing it.
5. Commit and push.

Plugins may contain `commands/` (each `.md` file becomes a slash command),
`skills/` (each subdirectory with a `SKILL.md` becomes a skill), or both.

Adding a skill to an *existing* plugin needs no `marketplace.json` edit — the
new `skills/<name>/SKILL.md` ships with the next commit.

Scripts a skill shells out to belong in the plugin's `scripts/` directory, and
must be referenced as `${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh` — that variable
only resolves for an installed plugin, so a hardcoded relative path will break
once someone installs it.

## Layout

```
.claude-plugin/marketplace.json   # marketplace index
plugins/<name>/                   # one directory per plugin
docs/superpowers/specs/           # design docs
```
