---
name: handoff
description: Write or refresh a handoff file at the project root (HANDOFF.md, or HANDOFF-<name>.md for a named workstream) so the work can resume in a fresh session without losing context. "/handoff resume [name]" reads it, checks it against git, and offers to start the next step; "/handoff list" shows every handoff; "/handoff delete [name]" removes a finished one.
argument-hint: "[name] | resume [name] | list | delete [name]"
disable-model-invocation: true
allowed-tools: Bash(git rev-parse *) Bash(git branch *) Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git ls-files *) Bash(date *)
---

# Handoff

Arguments: `$ARGUMENTS`

| Arguments | Mode | Target file |
|---|---|---|
| *(empty)* | **Write** | `HANDOFF.md` |
| `<name>` | **Write** | `HANDOFF-<name>.md` |
| `resume` | **Resume** | picked as described in Resume mode |
| `resume <name>` | **Resume** | `HANDOFF-<name>.md` |
| `list` | **List** | all of them |
| `delete` | **Delete** | picked as described in Delete mode |
| `delete <name>` | **Delete** | `HANDOFF-<name>.md` |

**Names**: lowercase the name, then it must match `^[a-z0-9]+(-[a-z0-9]+)*$` (letters, digits, single hyphens; at most 40 characters) and must not be `resume`, `list` or `delete`. If a name is invalid, or there are extra words, reply with the valid forms from the table above, then stop.

## Project root and handoff files

Run `git rev-parse --show-toplevel`. If it succeeds, that is the root and this is a git repo. If it fails, use the current working directory as the root and skip every git step below (write "not a git repo" where a branch would go).

Handoff files live only at `<root>`: `HANDOFF.md` (the unnamed one) and `HANDOFF-<name>.md` (named ones). To find them, glob `<root>/HANDOFF.md` and `<root>/HANDOFF-*.md`. A file's **label** is its name, or `(default)` for `HANDOFF.md`.

## Write mode

### 1. Gather

- **Conversation**: review the whole session: the goal, what was built or changed, what failed and why, decisions and rejected alternatives, commands run and their results, and the exact point where work stopped.
- **Git** (if a repo): `git branch --show-current`, `git status --short`, `git diff --stat`, `git diff --cached --stat`, `git log --oneline -10`, `git rev-parse --short HEAD`.
- **Time**: `date "+%Y-%m-%d %H:%M %Z"`.
- **Existing context**: read the target file if it exists, and every CLAUDE.md that applies (`<root>/CLAUDE.md`, `<root>/.claude/CLAUDE.md`, CLAUDE.md files in directories you worked in, `~/.claude/CLAUDE.md`). Nothing those files already say goes into the handoff.
- **Scope**: for a named handoff, keep only what belongs to that workstream; leave out work from this session that belongs to another one.
- **Verify**: confirm that every path you will list exists. Mark something "working" only if it was actually run or tested this session; otherwise write "untested".

### 2. Write the target file with this structure

```markdown
# Handoff — <project name>[ · <name>]

**Updated:** YYYY-MM-DD HH:MM TZ · **Branch:** `<branch>` · **Last commit:** `<short hash>`

## Goal
<1–3 sentences>

## Current state
- <done and working; say how it was verified>

## In progress
- <item> — `<path>`: <exactly where it stopped, what is half-done>

## To do
1. <highest priority first>

## Decisions
- **<choice>** — <rationale>. Rejected: <alternative> (<why>).

## Key files
- `<path>` — <one-line role>

## Gotchas
- <bug hit, surprising behavior, or dead end not to retry>

## Useful commands
- Build: `<cmd>`
- Test: `<cmd>`
- Run: `<cmd>`
- Deploy: `<cmd>`

## Next step
<one precise, concrete action: which file, function, or command to start with>

## History
- YYYY-MM-DD — <one-line summary of the session>
```

Write "None." under a section that has nothing; omit a command line that doesn't apply. Add ` · <name>` to the title only for a named handoff.

### 3. Rules

- **Concise**: under 150 lines. Bullets, not paragraphs. No filler.
- **No code**: never paste code or diffs. Point to `path` or `path:line` instead. One-line shell commands in "Useful commands" are the only exception.
- **No duplication with CLAUDE.md**: leave out conventions, commands, and architecture notes already documented there.
- **Rewrite, don't append**: if the target file exists, replace it with one current picture. Remove items that are done or obsolete. Keep still-open items, decisions, and gotchas from the old file that still apply, even if this session didn't touch them.
- **History**: newest first, at most 3 lines, one line per session. Add this session; drop the oldest beyond 3.
- **Paths**: relative to the root.
- **Secrets**: never write API keys, passwords, tokens, credentials in connection strings or URLs, or the contents of `.env` or other credential files. Refer to them only by variable name and location (e.g. "`STRIPE_KEY` in `.env`"). Before saving, reread the file and strip anything secret-like.
- **No side effects**: don't commit the handoff file or edit `.gitignore` unless the user asks. Never touch other handoff files.

### 4. Report

Show exactly 3 lines:
1. What this session accomplished.
2. What is in progress or blocking.
3. The next step.

If this is a named handoff and both "In progress" and "To do" are "None.", add: "This workstream looks finished: `/handoff delete <name>` removes its file."

Then end with:

> Run `/clear`, then start the next session with: **`/handoff resume`** (or **`/handoff resume <name>`** for a named handoff).

## Resume mode

1. **Pick the file**:
   - With a name: `HANDOFF-<name>.md`. If it doesn't exist, say so, show the List mode table if any handoff exists, and stop.
   - Without a name: if no handoff file exists, say so, suggest running `/handoff` (or `/handoff <name>`) at the end of a session, and stop. If exactly one exists, use it. If several exist, show the List mode table, ask which one to resume, and stop until the user answers.
2. **Summarize** in at most 5 lines: the goal, the current state, where work stopped, the next step, and how old the file is (from its header).
3. **Check against git** (if not a repo, say the check was skipped):
   - Branch: current branch vs the header's branch.
   - Commits since the handoff: `git log --oneline <last commit>..HEAD` (fall back to `git log --oneline --since="<header date and time>"` if that hash is unknown).
   - Working tree: `git status --short` and `git diff --stat` vs "In progress": uncommitted changes the file doesn't mention, or described work that is no longer there. Changes that clearly belong to another named handoff are not discrepancies; say which one they belong to.
   - Key files: each listed path still exists (flag deleted or renamed ones).
   - Spot-check claims in "Current state" and "In progress" that name a specific file or function, when that takes only a quick read.
   - Ignore every handoff file in these checks.

   Report a **Discrepancies** list, or "No discrepancies found."
4. **Offer** to start on the next step: restate it and ask whether to begin. If discrepancies make it questionable, say so and propose an adjusted step. Don't edit files or run anything beyond the read-only checks above until the user says yes.

## List mode

Read the header and the "Next step" of every handoff file and show one table, most recently updated first:

| Label | Updated | Branch | Next step |
|---|---|---|---|

Keep "Next step" to one short line. Mark a file **stale** if it was updated more than 14 days ago, and a named one **finished?** if both "In progress" and "To do" are "None.". If no handoff file exists, say so. Read only; change nothing.

## Delete mode

1. **Pick the file**:
   - With a name: `HANDOFF-<name>.md`. If it doesn't exist, say so, show the List mode table if any handoff exists, and stop.
   - Without a name: if no handoff file exists, say so and stop. Otherwise show the List mode table, ask which one to delete, and stop until the user answers. Never pick one on your own, even if only one exists.
2. **Inspect** the file and show:
   - Its label, "Updated" date and branch.
   - Open work: the items under "In progress" and "To do". If either is not "None.", warn that the workstream does not look finished.
   - Anything under "Decisions" or "Gotchas" that is worth keeping beyond this workstream (a lasting convention, a trap that will recur). Suggest moving it to the project's CLAUDE.md first; don't move it yourself unless the user asks.
   - Recoverability: run `git ls-files --error-unmatch <file>` (if a repo). Tracked → "recoverable from git history". Untracked or not a repo → "permanent, cannot be undone".
3. **Confirm**: ask "Delete `<file>`? (<recoverability>)" and stop until the user answers. Only an explicit yes in their reply counts.
4. **Delete** on yes: `rm "<root>/<file>"`. Delete only that file; never another handoff, never with a wildcard. Don't commit; if the file was tracked, say the deletion is left uncommitted.
5. **Report** in one line what was deleted, and how many handoff files remain.
