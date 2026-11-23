---
name: user-guide
description: Write or update the end-user guide (HTML + PDF + real screenshots) for a feature that changes how people use an app's interface, following the project's existing guide conventions or a bundled template. Use after finishing a feature, lot or PR that adds or changes screens, buttons, fields, flows or user-facing messages, or when asked for "/user-guide", "a user guide", "un guide utilisateur", "documente la feature pour les utilisateurs". Skip backend-only changes.
argument-hint: "[feature name] [base ref, default the main branch]"
---

# User guide

Produce a user guide for the feature just built: for the people who use the app, not developers.
Task-oriented, plain language, real screenshots, delivered as an HTML source and its PDF.

Arguments (`$ARGUMENTS`): an optional feature name and an optional base ref. With none, the feature
is the current branch's diff against the main branch.

## 0. Learn the project's conventions first

1. Read the project's `CLAUDE.md` / `AGENTS.md` for guide instructions (location, language,
   format, commit style). They override this skill.
2. Look for existing user guides: `docs/guide-utilisateur/`, `docs/user-guide*/`, `docs/guides/`,
   or `git ls-files | grep -i -E 'guide|manual|help'`, plus scripts that build them
   (`scripts/*guide*`, `scripts/*capture*`).
3. **If guides exist, copy their conventions exactly**: folder, file naming, `<head>`/stylesheet and
   cover (copy verbatim from the most recent guide, never restyle), screenshot script pattern,
   captures README, PDF build script, commit message shape. The rest of this skill only fills gaps.
4. **If none exist**, propose to the user in one message, then proceed on their OK:
   - location `docs/user-guide/` (or the language's equivalent, e.g. `docs/guide-utilisateur/`),
   - language = the language of the product's UI copy,
   - format = `template.html` from this skill's directory (A4 print stylesheet, cover with TOC,
     steps, notes, figures, tables), rendered to PDF with Chrome headless (step 5).

## 1. Decide whether a guide is needed, and which one

1. Read the change: `git log <base>..HEAD` with commit bodies, `git diff --stat <base>...HEAD`, and
   any `HANDOFF*.md`, plan or changelog that describes the feature.
2. A guide is needed only if a user would see or do something differently: new or changed pages,
   panels, buttons, fields, wizard steps, settings, user-facing messages or limits. Pure backend,
   refactors, tests, internals with no visible effect: stop and say so in one line, naming what you
   checked.
3. If the feature extends an area that already has a guide, **update that guide** (new or revised
   section, new captures, bump the version date) rather than writing a second one. Otherwise create
   a new guide with a short kebab-case slug in the guide language.
4. Tell the user in one or two lines which guide you will write or update and its outline (section
   titles) before producing captures.

## 2. Gather the facts from the code, never from memory

- Every UI label, button, tab, menu entry, badge, empty state and error message quoted in the guide
  is copied from the source (grep the strings, including i18n files). Quote them exactly (in the
  template: `<span class="ui">…</span>`); never paraphrase a label.
- Find the path to the feature: menu entry, page, step, panel, tab. Note prerequisites (role,
  setting, integration, key configured by an admin).
- Note what costs time or money (AI calls, paid API credits), what is saved and where, what runs
  automatically vs on click, limits and known gaps. Users need these.
- Collect user-facing error messages with their cause and fix for the troubleshooting table.

## 3. Screenshots

Captures are taken by a script kept in the repo, so they can be retaken after a UI change.

- Reuse or extend the project's capture script if there is one. Otherwise write
  `scripts/guide-captures-<slug>.mjs` with Playwright (`playwright-core` + the system Chrome if the
  project has it; ask before adding a dev dependency): viewport 1440×900, `deviceScaleFactor: 2`,
  locale and timezone of the product, base URL of the local dev server, output dir from `OUT`. A
  header comment says what it shoots, what it costs and the exact command.
- **No paid calls by default.** Intercept the app's API routes and abort those that spend money
  (AI, paid SEO/data providers, email/SMS, payments). When a screen needs their output, replay a
  fixture (`scripts/guide-captures-<slug>.fixture.json`) recorded from a real local run or built
  from local data. If a paid call is unavoidable, state its cost and ask the user before running.
- **Local environment only**: the dev server (start it with the preview tools / the project's
  launch config, or ask the user) and the local database. Log in with a local test account from
  the project's seed or test config, passed through env vars; never production, never a real
  password.
- Realistic demo content, no personal data.
- Files `NN-short-name.png` in `<guides dir>/captures/<slug>/`. Crop to the element
  (`locator.screenshot` or a clip) when the full page would make the subject unreadable.
- A `captures/<slug>/README.md`: date and environment, how the data was obtained (fixture, no paid
  call), the regeneration command, and a table file → what it shows.
- Look at every PNG (Read tool) before using it: loaded state, no stray spinner, no error toast, no
  dev overlay, no personal data.

## 4. Write the guide

- Cover: eyebrow ("Guide utilisateur" / "User guide"), the feature name as `<h1>`, a one-sentence
  lede (what it lets the user do), the numbered table of contents, and a meta line with the version
  date and where the captures were taken.
- Usual sections, adapted to the feature:
  1. What it is for (and where its data comes from, in a note)
  2. Prerequisites / settings (who can do it, what to configure first)
  3. The task sections, in the order users meet them: numbered steps for procedures, one figure per
     key screen, numbered figure captions
  4. Good practices and limits
  5. Messages and solutions (table: message → cause → what to do)
- Style: address the reader directly (vouvoiement in French), short sentences, the users'
  vocabulary, never internal names (ticket ids, function, table or route names). Say what happens
  after each action and how long it takes. No marketing tone.
- Put a comment at the top of the HTML with the command that rebuilds its PDF.

## 5. Render and check

1. Build the PDF with the project's script if it has one. Otherwise, from the guide's directory:
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-pdf-header-footer --print-to-pdf=guide-<slug>.pdf "file://$PWD/guide-<slug>.html"
   ```
   (`CHROME_PATH` or `chromium` on other systems.)
2. Read the PDF (Read tool, `pages`) and check: no figure split across pages, no heading alone at a
   page bottom, no blank page, TOC numbers match the sections, every image loads. Fix with page
   breaks (`section.page`), a top margin on a heading or a smaller figure class, then re-render.
3. Re-grep every quoted label in the source, in case the UI changed meanwhile.

## 6. Hand over

- Add the guide to the docs index or changelog if the project lists its guides.
- Summarize: guide path, page count, captures taken, anything you could not show (and why), and any
  paid call made.
- Do not commit unless asked. When asked, one commit with HTML + PDF + captures + capture script +
  fixture, in the project's commit style, whose body says what the guide covers and how to
  reproduce the captures without cost.
