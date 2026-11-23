# Personal Claude Code skills

Personal skills, available in every project on this machine.

## Layout

```
skills/<name>/SKILL.md   one directory per skill (plus any supporting files)
install.sh               symlinks each skill into ~/.claude/skills/
```

## Install

```bash
./install.sh
```

Each `skills/<name>` becomes a symlink at `~/.claude/skills/<name>`, so edits here are live in Claude Code. The script is idempotent and never overwrites an existing entry. Set `CLAUDE_SKILLS_DIR` to link somewhere else.

## Add a skill

1. Create `skills/<name>/SKILL.md` (frontmatter reference: https://code.claude.com/docs/en/skills).
2. Run `./install.sh`.
3. Invoke it with `/<name>` (run `/reload-skills` if it doesn't show up).

## Skills

| Skill | Usage | Purpose |
|---|---|---|
| [handoff](skills/handoff/SKILL.md) | `/handoff [name]`, `/handoff resume [name]`, `/handoff list`, `/handoff delete [name]` | Write HANDOFF.md (or HANDOFF-&lt;name&gt;.md per workstream) at the end of a session; resume from it in a fresh one; list or delete finished ones. |
| [standup](skills/standup/SKILL.md) | `/standup [today \| yesterday \| week \| <N>d \| since <date>]` | Read-only progress recap (done / in progress / next / blockers) from git, GitHub PRs and HANDOFF files; adds the touched Aporia tickets and features, and what needs an `/aporia-sync`, when the project's Aporia MCP server is connected. |
