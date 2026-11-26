---
name: standup
description: Recap a project's progress as a standup (done / next / blockers) from git history, GitHub PRs, the project's HANDOFF files and, when the project's Aporia MCP server is connected, the Aporia tasks and specifications the work touched. Read-only. Use for "/standup", a daily standup, "recap", "where are we on this project", "what did I do yesterday / this week", or a progress update to share.
argument-hint: "[today | yesterday | week | <N>d | since <YYYY-MM-DD>]"
allowed-tools: Bash(git rev-parse *) Bash(git config *) Bash(git log *) Bash(git branch *) Bash(git status *) Bash(git diff *) Bash(git for-each-ref *) Bash(git remote *) Bash(gh pr list *) Bash(gh pr view *) Bash(gh auth status *) Bash(date *) mcp__aporia__get_context mcp__aporia__list_tasks mcp__aporia__get_task mcp__aporia__list_specs mcp__aporia__get_spec mcp__aporia__list_ideas mcp__aporia__get_idea
---

# Standup

Arguments: `$ARGUMENTS`

Produce a short, shareable progress recap for the **current project**, from what the repository and its tools actually show. Never invent work, plans or blockers: every bullet traces to a commit, a PR, a handoff file, an Aporia task or specification, or something the user said in this session.

## Hard rules

- **Read-only.** Change nothing: no commit, no push, no file written, no PR or Aporia task touched.
- **Aporia is read-only too.** Allowed: `get_context`, `list_tasks`, `get_task`, `list_specs`, `get_spec`, `list_ideas`, `get_idea` (and `get_architecture`, `read_attachment` if ever needed). Forbidden: `take_task` (it moves the task to In progress and makes the user its owner), `report_task`, `create_task`, `update_task`, `deposit_idea`, `add_clause`, `revise_clause`, `write_intention`, `record_session_notes`, `attach_file`, and every other tool that writes (`create_specs`, `propose_spec_update`, `write_schema`, `write_architecture`, `propose_persona`, `link_personas`). Writing back to Aporia is the job of the `aporia-*` skills (`/aporia-report` above all); this skill only *suggests* running them.
- **Language.** Write the standup in the language the user is speaking (headings included).
- **Secrets.** Never print tokens, keys or `.env` contents, even if a commit message or PR body contains one.

## 1. Period

| Argument | Period start |
|---|---|
| *(empty)* | start of the previous working day (on Monday: last Friday 00:00) |
| `today` | today 00:00 |
| `yesterday` | yesterday 00:00 (Monday: last Friday 00:00) |
| `week` | Monday of the current week 00:00 |
| `<N>d` (e.g. `3d`) | N days ago 00:00 |
| `since <YYYY-MM-DD>` | that date 00:00 |

Anything else: reply with the forms in this table and stop. Get today's date with `date "+%Y-%m-%d %A"`. Call the start `<since>` below.

## 2. Gather (run independent commands in parallel)

**Project.** `git rev-parse --show-toplevel`. If it fails, this is not a git repo: skip the git and GitHub steps, use only HANDOFF files, Aporia and the conversation, and say so in the header. Project name = the root's directory name.

**Me.** `git config user.email` and `git config user.name`. Only this author's work counts as "done" (the recap is the user's own standup). If the user asks for the whole team, drop the author filter and attribute each item to its author.

**Commits.**
- `git log --all --source --author="<email>" --since="<since>" --no-merges --date=short --format="%h %ad %S | %s"` (`%S` is the branch each commit was reached from).
- A squash-merged change shows up twice: the branch commit and its copy on the default branch with a ` (#<n>)` suffix. Count it once, as the merged PR.
- Don't read diffs unless a commit message is too vague to summarize; then `git log -1 --stat <hash>`.

**Branches.** `git branch --show-current`, `git status --short`, and `git for-each-ref --sort=-committerdate --format="%(refname:short) %(committerdate:short) %(upstream:track)" refs/heads` for local branches touched in the period (unpushed work shows as `[ahead N]`).

**GitHub PRs** (only if `git remote -v` points at github.com and `gh auth status` succeeds; otherwise skip silently):
- `gh pr list --author @me --state all --search "updated:>=<since as YYYY-MM-DD>" --json number,title,body,state,url,headRefName,isDraft,reviewDecision,mergedAt,statusCheckRollup --limit 30` (`body` is only scanned for task numbers in step 3; never quote it).
- From `statusCheckRollup`, a PR is **failing** if any check concluded `FAILURE`, `TIMED_OUT` or `CANCELLED`.

**Handoff files.** Read `<root>/HANDOFF.md` and `<root>/HANDOFF-*.md` if any (written by the `handoff` skill). Their "In progress", "To do" and "Next step" sections feed **Next**; their age matters (older than 14 days = stale, mention it).

**Conversation.** If this session already did work, it counts too (it may not be committed yet).

## 3. Aporia (only when connected)

Aporia is connected when the tools of the `aporia` MCP server are available in this session (e.g. `aporia:get_context`). If they aren't, skip this whole section silently, with one exception: if `<root>/.agents/skills/aporia-*` or `<root>/.claude/skills/aporia-*` exists, add one line at the end saying the Aporia MCP server isn't connected in this session, so tasks weren't checked.

In Aporia, work is a **task** on a board, numbered `<prefix>-<n>` (e.g. `NEW-8`); a task may serve a **specification** (a key like `billing.invoices`, with an intention, criteria and rules). Board columns: Ready, Blocked and In progress belong to humans; On staging and In production are moved by git, when a pull request carrying the task's number deploys. A merged PR does not mean the task is in production.

1. `aporia:get_context`: take `product.name`, `product.shortCode` (the prefix, e.g. `NEW`) and the link template `ticketUrl`. Task numbers belong to **this** product only; ignore any other prefix.
2. **Find the tasks the work touched.** Collect every `<shortCode>-<n>` (case-insensitive: `new-8-persist-the-coupon`, `NEW-8`, `[NEW-8]`) found in branch names, commit subjects, and PR titles, branches and bodies from step 2, plus any task the HANDOFF files or the conversation mention. Deduplicate. Cap at 10, most recent first; say if some were left out.
3. **The user's own board:** `aporia:list_tasks { mine: true }` (send `next` back unchanged if `truncated`). It gives the tasks they own In progress, Blocked or Ready, even those no commit names. If **Next** has no evidence yet, `aporia:list_tasks { takeable: true }` gives the next task they could start (its first row).
4. **Read each task** from step 2: `aporia:get_task { task }` (a read; never `take_task`, which takes it). Add `workOrder: false` when only its stage and pull requests matter. Keep: number, `url`, title, type, `stage`, `owner` / `mine`, `blockedReason`, `waitsFor`, `pullRequests`, `release`, `lastActivityAt`, and the key of its specification.
5. **Specifications (at most 3,** the ones the tasks serve most): `aporia:get_spec { spec }`. Keep: whether its intention is signed, how many criteria the latest reports call `covered` / `notCovered` / `notVerified`, and its open tasks not already listed.
6. **Cross-check code vs board** (this is the coupling that matters):
   - Work in the period that carries **no task number** (commits, branch or PR) → it ships under no task: suggest `/aporia-report`, which files a task for it.
   - A PR of the period names a task but the task lists no such PR in `pullRequests` → the PR isn't linked (the number must be in its branch or title), so it will never carry the task to production: flag it.
   - A task was worked in the period but its `lastActivityAt` is older than `<since>` → the work wasn't reported on the task: suggest `/aporia-report`.
   - The session or the commits clearly settled a decision, a rule or an open question that isn't in Aporia → suggest `/aporia-report` (it routes ideas, clauses and session notes; don't file anything).
   - A task is **Blocked** → its `blockedReason` is a **blocker**. A task `waitsFor` another still open → a dependency, list it under **Blockers** when it stops the work.
   - A specification being worked has an **unsigned** intention → it's a draft waiting for a human signature: say so.

Never move, report, comment or claim to "fix" a mismatch: list it under **To sync** and name the skill that handles it.

## 4. Write the standup

Group work by **topic** (one task, one PR or one branch = one bullet), never one bullet per commit. Say what changed for the product, not the mechanics ("coupon validation now rejects expired codes", not "edit coupon.ts"). Cite references inline: task number (linked with `ticketUrl` when Aporia is connected), PR as a markdown link with its full URL (`[#12](https://github.com/owner/repo/pull/12)`), short commit hash only when there is no PR.

```markdown
## Standup — <project>[ · Aporia: <product name>] · <date>
_Period: since <since> · Branch: `<current branch>`_

### Done
- <outcome> — `<TASK>` · [#<n>](<url>) merged

### In progress
- <what> — `<branch>`<, unpushed: N commits><, PR [#n](<url>) open / draft / changes requested / CI failing>

### Next
- <from HANDOFF "Next step"/"To do", the user's Ready or In progress tasks, open PRs awaiting something>

### Blockers
- <blocker> — <why, who can unblock>

### Product side (Aporia)
- `<TASK>` <type> · <stage> — <title><, blocked: reason>
- Spec `<key>`: <N>/<M> criteria covered<, intention unsigned><, K open tasks>

### To sync
- <mismatch> → `/aporia-report` | link the PR to `<TASK>`
```

- Omit **Product side** and **To sync** when Aporia isn't connected or has nothing to say. Write "None." under Done / In progress / Next / Blockers when empty, rather than dropping them.
- **Blockers** are only real ones: a failing check, changes requested, a Blocked task with its reason, an open task this one waits for, an external dependency named in a handoff or the conversation. No speculative risks.
- **Next** comes only from evidence (handoff, open PRs, the user's Ready or In progress tasks, the next takeable task, what the user said). If there is none, write "None." and, in the closing line, ask the user what they plan.
- Keep the whole thing under ~30 lines. If the period had nothing, say "No activity since <since>" and offer a wider period (e.g. `/standup week`).

## 5. After the standup

End with at most two short lines:
- what was skipped and why (no GitHub access, Aporia not connected, tasks capped, stale handoff);
- the single most useful follow-up, if any (`/aporia-report`, `/aporia-work <TASK>` for the next task, `/handoff`, or a reformat: "I can reformat it for Slack or email").

Run nothing else. Don't offer to commit or post anything.
