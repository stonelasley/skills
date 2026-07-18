---
name: example-skill
description: Use when the user asks to verify the st1-skills marketplace setup, or asks for the layout of a new plugin in this marketplace - explains the directory structure and the files a plugin needs.
---

# Example Skill

This skill exists to prove that skills packaged in an `st1-skills` plugin load
correctly, and to serve as the template for real skills.

## Plugin layout

A plugin in this marketplace looks like this:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # name, description (no version — see below)
├── commands/
│   └── <command>.md         # each file becomes /<command>
└── skills/
    └── <skill-name>/
        └── SKILL.md         # frontmatter: name, description
```

Both `commands/` and `skills/` are optional — include whichever the plugin needs.

## Adding a new plugin

1. Copy this layout to `plugins/<new-name>/`.
2. Set `name` and `description` in its `plugin.json`. Leave `version` out — with
   no `version`, the git commit SHA is the version, so every pushed commit
   reaches users. A pinned `version` string blocks updates until it is bumped.
3. Add a matching entry to `.claude-plugin/marketplace.json` with a `source`
   of `./plugins/<new-name>`.
4. Commit and push, then run `/plugin marketplace update st1-skills` on other
   machines.

Adding a skill to an *existing* plugin needs no marketplace edit — the new
`skills/<name>/SKILL.md` ships with the next commit.

## Writing the description field

The `description` in a skill's frontmatter is what Claude reads to decide whether
the skill applies. Write it as "Use when..." and name the concrete triggers —
the situations, phrasings, or file types that should pull the skill in. A vague
description means the skill never fires.
