---
name: handoff
description: Write or refresh HANDOFF.md at the project root so the work can resume in a fresh session without losing context. "/handoff resume" reads HANDOFF.md, checks it against git, and offers to start the next step.
argument-hint: "[resume]"
disable-model-invocation: true
allowed-tools: Bash(git rev-parse *) Bash(git branch *) Bash(git status *) Bash(git diff *) Bash(git log *) Bash(date *)
---

# Handoff

Mode argument: `$ARGUMENTS`

- Empty → run **Write mode**.
- `resume` → run **Resume mode**.
- Anything else → reply that the valid forms are `/handoff` and `/handoff resume`, then stop.

## Project root

Run `git rev-parse --show-toplevel`. If it succeeds, that is the root and this is a git repo. If it fails, use the current working directory as the root and skip every git step below (write "not a git repo" where a branch would go). The file is always `<root>/HANDOFF.md`.

## Write mode

### 1. Gather

- **Conversation**: review the whole session: the goal, what was built or changed, what failed and why, decisions and rejected alternatives, commands run and their results, and the exact point where work stopped.
- **Git** (if a repo): `git branch --show-current`, `git status --short`, `git diff --stat`, `git diff --cached --stat`, `git log --oneline -10`, `git rev-parse --short HEAD`.
- **Time**: `date "+%Y-%m-%d %H:%M %Z"`.
- **Existing context**: read `<root>/HANDOFF.md` if it exists, and every CLAUDE.md that applies (`<root>/CLAUDE.md`, `<root>/.claude/CLAUDE.md`, CLAUDE.md files in directories you worked in, `~/.claude/CLAUDE.md`). Nothing those files already say goes into HANDOFF.md.
- **Verify**: confirm that every path you will list exists. Mark something "working" only if it was actually run or tested this session; otherwise write "untested".

### 2. Write `<root>/HANDOFF.md` with this structure

```markdown
# Handoff — <project name>

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

Write "None." under a section that has nothing; omit a command line that doesn't apply.

### 3. Rules

- **Concise**: under 150 lines. Bullets, not paragraphs. No filler.
- **No code**: never paste code or diffs. Point to `path` or `path:line` instead. One-line shell commands in "Useful commands" are the only exception.
- **No duplication with CLAUDE.md**: leave out conventions, commands, and architecture notes already documented there.
- **Rewrite, don't append**: if HANDOFF.md exists, replace it with one current picture. Remove items that are done or obsolete. Keep still-open items, decisions, and gotchas from the old file that still apply, even if this session didn't touch them.
- **History**: newest first, at most 3 lines, one line per session. Add this session; drop the oldest beyond 3.
- **Paths**: relative to the root.
- **Secrets**: never write API keys, passwords, tokens, credentials in connection strings or URLs, or the contents of `.env` or other credential files. Refer to them only by variable name and location (e.g. "`STRIPE_KEY` in `.env`"). Before saving, reread the file and strip anything secret-like.
- **No side effects**: don't commit HANDOFF.md or edit `.gitignore` unless the user asks.

### 4. Report

Show exactly 3 lines:
1. What this session accomplished.
2. What is in progress or blocking.
3. The next step.

Then end with:

> Run `/clear`, then start the next session with: **Read HANDOFF.md and continue from the next step.**

## Resume mode

1. **Read** `<root>/HANDOFF.md`. If it doesn't exist, say so, suggest running `/handoff` at the end of a session, and stop.
2. **Summarize** in at most 5 lines: the goal, the current state, where work stopped, the next step, and how old the file is (from its header).
3. **Check against git** (if not a repo, say the check was skipped):
   - Branch: current branch vs the header's branch.
   - Commits since the handoff: `git log --oneline <last commit>..HEAD` (fall back to `git log --oneline --since="<header date and time>"` if that hash is unknown).
   - Working tree: `git status --short` and `git diff --stat` vs "In progress": uncommitted changes the file doesn't mention, or described work that is no longer there.
   - Key files: each listed path still exists (flag deleted or renamed ones).
   - Spot-check claims in "Current state" and "In progress" that name a specific file or function, when that takes only a quick read.
   - Ignore HANDOFF.md itself in these checks.

   Report a **Discrepancies** list, or "No discrepancies found."
4. **Offer** to start on the next step: restate it and ask whether to begin. If discrepancies make it questionable, say so and propose an adjusted step. Don't edit files or run anything beyond the read-only checks above until the user says yes.
