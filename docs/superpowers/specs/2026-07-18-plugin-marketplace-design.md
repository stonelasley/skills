# st1-skills Plugin Marketplace — Design

**Date:** 2026-07-18
**Status:** Approved (Option A — monorepo marketplace)

## Purpose

Turn this repository (`stonelasley/skills` on GitHub) into a personal Claude Code
plugin marketplace named `st1-skills`. Primary content: skills and slash commands.
Audience: the author, synced across machines via GitHub.

## Architecture

Monorepo marketplace: the repo holds both the marketplace index and all plugins,
referenced by relative paths. One `git push` publishes updates; machines pick them
up on marketplace refresh.

```
skills/
├── .claude-plugin/
│   └── marketplace.json      # marketplace index: name "st1-skills", owner, plugin list
├── plugins/
│   └── starter/              # example plugin proving the end-to-end flow
│       ├── .claude-plugin/
│       │   └── plugin.json   # name, description, version
│       ├── commands/
│       │   └── hello.md      # /hello slash command
│       └── skills/
│           └── example-skill/
│               └── SKILL.md  # small demonstrative skill
└── README.md                 # how to add the marketplace + install plugins
```

## Components

### marketplace.json
- `name`: `st1-skills` (used as the `@st1-skills` suffix when installing)
- `owner`: Stone C. Lasley
- `plugins`: array; each entry has `name`, `source` (relative path, e.g.
  `./plugins/starter`), and `description`.

### starter plugin
- `plugin.json`: name and description only. **No `version` field** — a pinned
  version blocks updates for already-installed users until the string is bumped;
  omitting it makes the git commit SHA the version so every push propagates.
- `commands/hello.md`: a minimal `/hello` command with frontmatter `description`,
  demonstrating command structure.
- `skills/example-skill/SKILL.md`: a minimal skill with `name` and `description`
  frontmatter, demonstrating skill structure and trigger phrasing.

### README.md
- Adding the marketplace: `/plugin marketplace add stonelasley/skills`
- Installing a plugin: `/plugin install starter@st1-skills`
- How to add a new plugin: copy the `starter/` layout, add an entry to
  `marketplace.json`, bump version, push.

## Data flow / usage

1. On any machine: `/plugin marketplace add stonelasley/skills`.
2. `/plugin install <plugin>@st1-skills` enables that plugin's skills and commands.
3. Updates: edit locally → commit → push → `/plugin marketplace update st1-skills`
   (or automatic refresh) on other machines.

## Error handling

- JSON validity is the main failure mode: validate `marketplace.json` and
  `plugin.json` with `jq` (or equivalent) before committing.
- Relative `source` paths must resolve from the repo root; verified by local
  install test.

## Testing

1. Validate all JSON files parse.
2. Add the marketplace from the local path (`/plugin marketplace add
   /home/st1/Projects/st1/skills`) and install `starter` to prove the flow
   end-to-end before pushing to GitHub.
3. Confirm `/hello` appears and the example skill is listed.

## Out of scope (YAGNI)

- Agents, hooks, MCP servers (can be added to plugins later — the format allows it).
- Contribution guidelines / community process (personal marketplace).
- CI validation (may add later if JSON breakage becomes a problem).
