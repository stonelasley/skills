# st1-skills

A personal [Claude Code](https://claude.com/claude-code) plugin marketplace —
skills and slash commands, synced across machines via this repository.

## Install

Add the marketplace once per machine:

```
/plugin marketplace add stonelasley/skills
```

Then install any plugin from it:

```
/plugin install starter@st1-skills
```

To verify the install worked, run `/hello`.

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
2. Set `name`, `description`, and `version` in its `.claude-plugin/plugin.json`.
3. Add a matching entry to `.claude-plugin/marketplace.json` with a `source` of
   `./plugins/<new-name>`.
4. Commit and push.

Plugins may contain `commands/` (each `.md` file becomes a slash command),
`skills/` (each subdirectory with a `SKILL.md` becomes a skill), or both.

## Layout

```
.claude-plugin/marketplace.json   # marketplace index
plugins/<name>/                   # one directory per plugin
docs/superpowers/specs/           # design docs
```
