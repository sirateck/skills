# Agent skills

Skills for [Claude Code](https://code.claude.com/docs/en/skills) (and other agents that read the `SKILL.md` format) that I use in my day-to-day work.

## Skills

| Skill | Usage | Purpose |
|---|---|---|
| [batch](skills/batch/SKILL.md) | `/batch <name> <ticket>… [--auto] [--parallel N] [--no-worktree]`, `/batch status [name]`, `/batch resume [name]`, `/batch abort <name>` | Ship several already-specified tickets as one verified, reviewed PR per ticket, squash-merged one by one into an integration branch, then one final PR to the default branch that a human merges. Dependency waves, parallel tickets in git worktrees, a resumable state file; works with Aporia, Linear or pasted specs. |
| [handoff](skills/handoff/SKILL.md) | `/handoff [name]`, `/handoff resume [name]`, `/handoff list`, `/handoff delete [name]` | Write HANDOFF.md (or HANDOFF-&lt;name&gt;.md per workstream) at the end of a session; resume from it in a fresh one; list or delete finished ones. |
| [standup](skills/standup/SKILL.md) | `/standup [today \| yesterday \| week \| <N>d \| since <date>]` | Read-only progress recap (done / in progress / next / blockers) from git, GitHub PRs and HANDOFF files; adds the touched Aporia tasks and specifications, the user's own board, and what needs an `/aporia-report`, when the project's Aporia MCP server is connected. |
| [user-guide](skills/user-guide/SKILL.md) | `/user-guide [feature] [base ref]` | End-user guide (HTML + PDF + real screenshots) for a feature that changes the UI: follows the project's existing guide conventions, else the bundled `template.html`; captures scripted on the local dev server with paid calls blocked. |

## Install

With the [skills CLI](https://skills.sh/):

```bash
npx skills add sirateck/skills
```

One skill only:

```bash
npx skills add sirateck/skills@standup
```

Add `-g` to install for your user (every project) instead of the current project. Then invoke a skill with `/<name>`.

## Develop locally

Clone the repo and link every skill into `~/.claude/skills/`:

```bash
./install.sh
```

Each `skills/<name>` becomes a symlink at `~/.claude/skills/<name>`, so edits in the repo are live in Claude Code. The script is idempotent and never overwrites an existing entry. Set `CLAUDE_SKILLS_DIR` to link somewhere else.

### Add a skill

1. Create `skills/<name>/SKILL.md` (frontmatter reference: https://code.claude.com/docs/en/skills).
2. Run `./install.sh`.
3. Invoke it with `/<name>` (run `/reload-skills` if it doesn't show up).
4. Add a row to the table above.

## License

[MIT](LICENSE)
