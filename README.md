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

Edit a plugin locally, commit, and push. On other machines:

```
/plugin marketplace update st1-skills
```

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
