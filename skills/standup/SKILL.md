---
name: standup
description: Recap a project's progress as a standup (done / next / blockers) from git history, GitHub PRs, the project's HANDOFF files and, when the project's Aporia MCP server is connected, the Aporia tickets and features the work touched. Read-only. Use for "/standup", a daily standup, "recap", "where are we on this project", "what did I do yesterday / this week", or a progress update to share.
argument-hint: "[today | yesterday | week | <N>d | since <YYYY-MM-DD>]"
allowed-tools: Bash(git rev-parse *) Bash(git config *) Bash(git log *) Bash(git branch *) Bash(git status *) Bash(git diff *) Bash(git for-each-ref *) Bash(git remote *) Bash(gh pr list *) Bash(gh pr view *) Bash(gh auth status *) Bash(date *) mcp__aporia__pull_constitution mcp__aporia__search_graph mcp__aporia__pull_context mcp__aporia__feature_gaps_spec
---

# Standup

Arguments: `$ARGUMENTS`

Produce a short, shareable progress recap for the **current project**, from what the repository and its tools actually show. Never invent work, plans or blockers: every bullet traces to a commit, a PR, a handoff file, an Aporia item, or something the user said in this session.

## Hard rules

- **Read-only.** Change nothing: no commit, no push, no file written, no PR or ticket touched.
- **Aporia is read-only too.** Allowed: `pull_constitution`, `search_graph`, `pull_context`, `feature_gaps_spec`, `fetch_personas`, `fetch_principles`, `read_attachment`, and `pull_item` **without `claim`** (omit the field; never pass `claim: true`, which assigns the ticket). Forbidden: `record_notes`, `comment_item`, `update_item`, `update_node`, `resolve_items`, `apply_scan`, `attach_file`, `record_process`, every `upsert_*`. Writing back to the map is the job of the `aporia-*` skills; this skill only *suggests* running them.
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
- `gh pr list --author @me --state all --search "updated:>=<since as YYYY-MM-DD>" --json number,title,body,state,url,headRefName,isDraft,reviewDecision,mergedAt,statusCheckRollup --limit 30` (`body` is only scanned for ticket ids in step 3; never quote it).
- From `statusCheckRollup`, a PR is **failing** if any check concluded `FAILURE`, `TIMED_OUT` or `CANCELLED`.

**Handoff files.** Read `<root>/HANDOFF.md` and `<root>/HANDOFF-*.md` if any (written by the `handoff` skill). Their "In progress", "To do" and "Next step" sections feed **Next**; their age matters (older than 14 days = stale, mention it).

**Conversation.** If this session already did work, it counts too (it may not be committed yet).

## 3. Aporia (only when connected)

Aporia is connected when the tools of the `aporia` MCP server are available in this session (e.g. `aporia:pull_constitution`). If they aren't, skip this whole section silently, with one exception: if `<root>/.agents/skills/aporia-*` or `<root>/.claude/skills/aporia-*` exists, add one line at the end saying the Aporia MCP server isn't connected in this session, so tickets weren't checked.

1. `aporia:pull_constitution`: take `product.shortCode` (e.g. `NEW`) and `product.name`. Ticket ids belong to **this** product only.
2. **Find the tickets the work touched.** Collect every `<shortCode>-<n>` (case-insensitive, e.g. `new-8-coupon-fix`, `NEW-8`, `[NEW-8]`) found in branch names, commit subjects, and PR titles, branches and bodies from step 2, plus any ticket the HANDOFF files or the conversation mention. Deduplicate. Cap at 10, most recent first; say if some were left out.
3. **Read each ticket:** `aporia:pull_item { ticket }`, **without `claim`**. Keep: kind, title, status (open / resolved / superseded), priority, claimedAt / assignee, and the map targets' feature keys.
4. **Features (at most 3,** the ones the tickets target most): `aporia:feature_gaps_spec { key }`. Keep: `built`, `readiness.status` (`ready` / `blocked` / `already_complete`) and why it is blocked, the count of `unbuilt` bindings, open questions on the critical path, and `openWork` items not already listed.
5. **Cross-check code vs map** (this is the coupling that matters):
   - A ticket's PR is **merged** but the ticket is still **open** → it needs a sync: suggest `/aporia-sync`.
   - A ticket is **resolved** but its branch still has unmerged commits → flag the mismatch.
   - The session or the commits clearly settled a decision or raised an open question that isn't on the map → suggest `/aporia-session-notes` (don't file anything).
   - A feature is `blocked` on open questions → those questions are **blockers**, with who owes the answer if the item says so.

Never resolve, comment or claim to "fix" a mismatch: list it under **To sync** and name the skill that handles it.

## 4. Write the standup

Group work by **topic** (one ticket, one PR or one branch = one bullet), never one bullet per commit. Say what changed for the product, not the mechanics ("coupon validation now rejects expired codes", not "edit coupon.ts"). Cite references inline: ticket id, PR as a markdown link with its full URL (`[#12](https://github.com/owner/repo/pull/12)`), short commit hash only when there is no PR.

```markdown
## Standup — <project>[ · Aporia: <product name>] · <date>
_Period: since <since> · Branch: `<current branch>`_

### Done
- <outcome> — `<TICKET>` · [#<n>](<url>) merged

### In progress
- <what> — `<branch>`<, unpushed: N commits><, PR [#n](<url>) open / draft / changes requested / CI failing>

### Next
- <from HANDOFF "Next step"/"To do", open claimed tickets, open PRs awaiting something>

### Blockers
- <blocker> — <why, who can unblock>

### Product side (Aporia)
- `<TICKET>` <kind> · <status> — <title>
- Feature `<name>`: <built | not built> · <ready | blocked: reason> · <N> bindings left to build

### To sync
- <mismatch> → `/aporia-sync` | `/aporia-session-notes`
```

- Omit **Product side** and **To sync** when Aporia isn't connected or has nothing to say. Write "None." under Done / In progress / Next / Blockers when empty, rather than dropping them.
- **Blockers** are only real ones: a failing check, changes requested, an unanswered blocking question, an external dependency named in a handoff or the conversation. No speculative risks.
- **Next** comes only from evidence (handoff, open PRs, claimed or open tickets, what the user said). If there is none, write "None." and, in the closing line, ask the user what they plan.
- Keep the whole thing under ~30 lines. If the period had nothing, say "No activity since <since>" and offer a wider period (e.g. `/standup week`).

## 5. After the standup

End with at most two short lines:
- what was skipped and why (no GitHub access, Aporia not connected, tickets capped, stale handoff);
- the single most useful follow-up, if any (`/aporia-sync`, `/aporia-session-notes`, `/handoff`, or a reformat: "I can reformat it for Slack or email").

Run nothing else. Don't offer to commit or post anything.
