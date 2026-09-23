# MDBOOK-PARAGRAPH-SPACING: Normalize mdBook Paragraph Separation

## Metadata

- Tree ID: `MDBOOK-PARAGRAPH-SPACING`
- Status: `active`
- Roadmap lane: `project documentation`
- Created: `2026-05-19`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Make the rendered mdBook easier to read and review by ensuring prose
paragraphs have clear visual separation instead of running together as large
text blobs, with source changes limited to those needed for the rendered
result.

## Non-Goals

- Do not change FSMGen behavior, ISF semantics, examples, commands, or
  feature claims.
- Do not rewrite chapter content for style beyond paragraph separation.
- Do not reflow code blocks, tables, lists, or generated book output by hand.

## Acceptance Criteria

- Chapter 12, chapter 14, and any other obvious mdBook prose blobs found in
  the audit are reformatted so adjacent paragraphs have one blank line.
- Markdown structures that depend on adjacency, including lists, tables,
  fenced code blocks, headings, and admonition-like blocks, remain intact.
- Rendered HTML no longer contains obvious long prose list-item blobs in the
  reported chapters.
- A browser-based regression audit checks the actual rendered HTML, including
  representative long chapters, ordinary paragraphs, list-contained prose,
  and the relevant theme/CSS behavior at recorded viewport and theme settings.
- `mdbook build docs/book` passes.
- A focused diff review confirms the slice is formatting-only.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-PARAGRAPH-SPACING`
  Status: `active`
  Goal: `Normalize mdBook prose paragraph separation without changing technical content.`
  Children: `MDBOOK-PARAGRAPH-SPACING.1, MDBOOK-PARAGRAPH-SPACING.2, MDBOOK-PARAGRAPH-SPACING.3, MDBOOK-PARAGRAPH-SPACING.4, MDBOOK-PARAGRAPH-SPACING.5`

- ID: `MDBOOK-PARAGRAPH-SPACING.1`
  Status: `done`
  Goal: `Create task-tree ownership and define the paragraph-spacing cleanup scope.`
  Acceptance: `Create this task tree, register it in docs/TASK_TREE.md, identify chapter 12 and chapter 14 as required audit targets, and keep implementation deferred to the next leaf.`
  Verification: `mdbook build docs/book; git diff --check; whitespace-normalized mdBook source comparison against HEAD`
  Commit: `a1144655 MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree`

- ID: `MDBOOK-PARAGRAPH-SPACING.2`
  Status: `done`
  Goal: `Normalize obvious mdBook prose paragraph blobs.`
  Acceptance: `Review the mdBook source, starting with chapter 12 and chapter 14, and insert one blank line between adjacent prose paragraphs where missing. Preserve code fences, tables, lists, examples, headings, and all technical wording. Update live docs with the formatting-only result.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `eebafed9 MDBOOK-PARAGRAPH-SPACING.2: normalize book paragraph spacing`

- ID: `MDBOOK-PARAGRAPH-SPACING.3`
  Status: `done`
  Goal: `Reopen the cleanup for rendered-HTML list-item blobs.`
  Acceptance: `Record that the first cleanup fixed ordinary paragraph boundaries but left long Markdown list items that render as single HTML list-item blobs, and select a follow-up leaf with rendered-HTML validation.`
  Verification: `mdbook build docs/book; rendered HTML audit identifies long list-item blobs`
  Commit: `1ccd62c9 MDBOOK-PARAGRAPH-SPACING.3: reopen rendered HTML blob cleanup`

- ID: `MDBOOK-PARAGRAPH-SPACING.4`
  Status: `done`
  Goal: `Split long rendered HTML list-item prose blobs.`
  Acceptance: `Audit the built mdBook HTML for long prose paragraphs and list items, split the remaining long list-item prose blobs into list-contained paragraphs without changing technical wording, preserve fences/tables/lists/examples/headings, and validate the rendered HTML no longer has obvious long blobs in the reported chapters.`
  Verification: `mdbook build docs/book; rendered HTML audit for long paragraphs and long list items; whitespace-normalized source comparison against HEAD; git diff --check`
  Commit: `3047fd10 MDBOOK-PARAGRAPH-SPACING.4: split rendered book prose blobs`

- ID: `MDBOOK-PARAGRAPH-SPACING.5`
  Status: `active`
  Goal: `Audit paragraph separation in the actual rendered mdBook with the in-app browser.`
  Children: `MDBOOK-PARAGRAPH-SPACING.5.1, MDBOOK-PARAGRAPH-SPACING.5.2, MDBOOK-PARAGRAPH-SPACING.5.3`

- ID: `MDBOOK-PARAGRAPH-SPACING.5.1`
  Status: `done`
  Goal: `Prepare a reproducible built-HTML shortlist for the visual review.`
  Acceptance: `Build from the clean source revision into a repository-local disposable directory; enumerate summary-linked chapters and select length-ranked paragraph/list-item candidates plus required Chapter 12/14 samples; retain the exact source/build identity, selection instrument, bounded review candidates and explicit limitations. HTML text length is triage, not a defect or visual-signoff claim. Preserve the observed browser initialization failures and the pending enablement question. No book-source formatting or product changes.`
  Verification: `At clean source 9c9db81c8 with mdbook v0.5.4, tracked census.py binds 72 source inputs and 63 rendered chapters and selects 28 distinct review candidates from 7498 nonempty paragraph and 2147 own-prose list-item records. These populations overlap. A separate raw-HTML oracle agrees with every paragraph length; list items have hand-labeled nested/scope controls. Those controls caught and repaired joined adjacent block text, and malformed nesting is rejected. An older source revision fails identity verification. Rebuilding reproduces the entire saved record. In-app cua.getState failed with CUA_REPL_ENABLED_SURFACES is required; the alternative node_repl tool failed while initializing its browser import. Neither produced a session or screenshot, and no visual/CSS signoff is claimed.`
  Commit: `MDBOOK-PARAGRAPH-SPACING.5.1 commit`

- ID: `MDBOOK-PARAGRAPH-SPACING.5.2`
  Status: `blocked`
  Goal: `Complete the actual browser DOM, CSS and visual spacing audit.`
  Acceptance: `Rebuild and rebind candidates if recorded source identities have moved, preserving the original capture. Serve the admitted build on loopback; inspect mandatory Chapter 12/14 and shortlist candidates with actual DOM metrics and screenshots in the in-app browser; record viewport, theme and computed CSS for ordinary paragraphs and list-contained prose. Select a bounded formatting-only repair only if a rendered defect is confirmed. Stop the server and close audit resources before handoff; no HTML-only visual signoff.`
  Verification: `On 2026-09-23 the director reported enabling full CDP, then Computer Use and the Chrome extension. Each fresh reset followed by cua.getState still failed with CUA_REPL_ENABLED_SURFACES is required before browser discovery. No browser review, viewport, effective CSS or screenshot evidence exists.`
  Blocked by: `Browser runtime initialization still fails after the reported Computer Use and Chrome setup. No connection is verified. A fresh chat or app restart is documented connection troubleshooting, not a confirmed remedy for this exact error. HIAL cleanup-first ordering is separately approved.`
  Commit: `pending`

- ID: `MDBOOK-PARAGRAPH-SPACING.5.3`
  Status: `blocked`
  Goal: `Repair confirmed source paragraph coalescence after the browser review.`
  Acceptance: `Use .5.2 to select the first bounded formatting-only repair from the retained candidate census. Source paragraphs in Chapters 14i and 14l currently coalesce repeated adjacent work-unit descriptions into single HTML paragraphs; verify actual visual impact, insert only necessary paragraph boundaries, preserve whitespace-normalized technical content and Markdown structure, rerun the census and browser checks, and commit each selected repair slice. No historical-truth rewrite or broader containment activation.`
  Verification: `Owned from .5.1 structural findings; the longest captured paragraph has 3626 whitespace tokens and the next 3271. An independent raw-HTML extraction agrees with every paragraph length. These facts establish tag/source coalescence, not a visual defect verdict; browser scope selection remains required.`
  Blocked by: `MDBOOK-PARAGRAPH-SPACING.5.2 actual browser review.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MDBOOK-PARAGRAPH-SPACING.5.2` | `blocked` | HTML candidates are retained; actual browser/CSS/visual signoff awaits runtime enablement. |

## Decisions

- `2026-05-19`: Treat the user-reported readability problem as a
  formatting-only mdBook source cleanup. Chapter 12 and chapter 14 are
  mandatory audit targets because the user called them out directly.
- `2026-05-19`: Reopened after rendered HTML review showed that ordinary
  Markdown paragraph splitting did not affect long list items, which still
  render as single `<li>` blobs unless list-contained paragraph breaks are
  inserted.
- `2026-08-01`: Park a non-urgent browser-based regression audit rather than
  inferring visual quality from Markdown source or build success alone. The
  audit must distinguish content structure from effective theme/CSS behavior
  and must not interrupt the active HIAL/VIAL frontier.

## Open Questions

- The director reports full CDP, Computer Use and Chrome extension setup on
  2026-09-23; the runtime error persists before browser discovery. Official
  connection troubleshooting includes a new chat or app restart:
  https://learn.chatgpt.com/docs/chrome-extension. Neither is verified as a
  remedy for this exact error. No visual signoff is available.

## Blockers

- `.5.2`: browser initialization fails before an enabled surface can be selected.
  HTML preparation is independent; it cannot satisfy the visual acceptance.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-19` | `MDBOOK-PARAGRAPH-SPACING.1` | `mdbook build docs/book`; `git diff --check` | `created task-tree ownership for the mdBook paragraph-spacing cleanup` |
| `2026-05-19` | `MDBOOK-PARAGRAPH-SPACING.2` | `mdbook build docs/book`; `git diff --check`; whitespace-normalized mdBook source comparison against `HEAD` | `normalized paragraph spacing across the named chapters and other obvious mdBook prose blobs without changing technical content` |
| `2026-05-19` | `MDBOOK-PARAGRAPH-SPACING.3` | `mdbook build docs/book`; rendered HTML audit | `confirmed the remaining rendered blobs are long list items, not ordinary paragraph tags` |
| `2026-05-19` | `MDBOOK-PARAGRAPH-SPACING.4` | `mdbook build docs/book`; rendered HTML audit for long paragraphs and long list items; whitespace-normalized source comparison against `HEAD`; `git diff --check` | `split rendered prose blobs across the built book without changing technical content` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MDBOOK-PARAGRAPH-SPACING.1` | `a1144655 MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree` | `creates ownership before book-source formatting edits` |
| `MDBOOK-PARAGRAPH-SPACING.2` | `eebafed9 MDBOOK-PARAGRAPH-SPACING.2: normalize book paragraph spacing` | `formatting-only mdBook source readability cleanup` |
| `MDBOOK-PARAGRAPH-SPACING.3` | `1ccd62c9 MDBOOK-PARAGRAPH-SPACING.3: reopen rendered HTML blob cleanup` | `reopens the task tree for HTML-visible list-item blobs` |
| `MDBOOK-PARAGRAPH-SPACING.4` | `3047fd10 MDBOOK-PARAGRAPH-SPACING.4: split rendered book prose blobs` | `validates the generated HTML directly` |

## Changelog

- `2026-05-19`: Created task tree and selected `.2` for the formatting-only
  mdBook paragraph-spacing cleanup.
- `2026-05-19`: Completed `.2` by adding blank-line paragraph separation to
  chapter 12, chapter 14, and other obvious mdBook prose blobs discovered by
  the audit.
- `2026-05-19`: Reopened with `.4` selected after rendered HTML inspection
  confirmed long list-item prose still displays as blobs.
- `2026-05-19`: Completed `.4` by splitting the remaining rendered long
  paragraphs and list-item blobs in the mdBook sources and included downstream
  ISF handoff document; generated HTML now passes the long-prose audit.
- `2026-08-01`: Reopened the tree as proposed and parked `.5` for a future
  in-app-browser regression audit of the actual rendered book. No mdBook
  content or presentation changed in this planning-only slice.


## Activation boundary (2026-09-23)

Unlimited PNT selects this independent maintenance audit after clean policy
revision `9c9db81c8`; it does not interrupt or admit the blocked HIAL launch.
The parent visual contract remains intact. The built-HTML preparation is a
separately committable leaf while browser access is unavailable. Historical
`completed` node spelling and quoted child lists are normalized to the current
integrity grammar; historical evidence and commit references remain unchanged.


## HTML preparation evidence (.5.1)

Retained instrument, independent paragraph oracle and capture:
`docs/audits/mdbook-spacing-preflight-20260923/`. Re-run against unchanged inputs:

```sh
mdbook build docs/book -d .artifacts/paragraph-spacing-book
python3 -B docs/audits/mdbook-spacing-preflight-20260923/census.py --build .artifacts/paragraph-spacing-book --qualify
python3 -B docs/audits/mdbook-spacing-preflight-20260923/oracle.py --build .artifacts/paragraph-spacing-book
```

`candidates.json` binds the full source revision, every consumed source digest,
producer digest, mdBook version and rendered chapter digests. The tracked
producer/capture and replay commands are the durability leg. If source or tool
identity moves, verification must fail; reconstruct the named source revision
in an owned repository-local worktree with the recorded tool version before
historical replay. The retained generated build is disposable, same-volume
`.artifacts/paragraph-spacing-book`; no server or browser job was started.
The installed mdBook executable is a required read-only toolchain dependency.

Re-derivation counts nonempty main-content prose, excluding preformatted,
table, script and style text. Paragraph and list-item samples overlap; nested
list-item text is excluded from its parent's own-prose count. Whitespace tokens
are triage metrics, never rendered height or defect counts. Exact browser
selectors plus zero-based indexes, heading IDs and text digests locate candidates.
The independent raw-HTML paragraph extraction and hand-labeled nesting controls
are the falsification evidence; there is no independent list-item population
census or browser oracle yet, and visual signoff remains expressly missing.

Source review confirms the two largest paragraph candidates consist of adjacent
work-unit descriptions without Markdown paragraph breaks. This is a structural
finding, now owned by .5.3; .5.2 must still determine visual impact and a safe
formatting-only repair. No word content or product claim was changed here.

## Acceptance Checklist (.5.1)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` for the exact `00d71114d`
  sentence in Chapter 14i locates `dc1c64afb LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8:
  partition Chapter 14 by topic`; that existing narrative survived partition.
  Current rendered candidates point to Chapter 14i's
  `00d71114d` narrative block and Chapter 14l's `.132` narrative block: ordinary
  source line breaks join into single HTML paragraphs. Browser initialization
  fails before a surface opens, so the remaining visual judgment stays blocked.
- [x] **ADDRESSED (verified)** — `census.py --qualify` reproduces the pinned
  capture and rejects malformed target nesting; its independent hand-labeled
  fixture caught block-boundary token merging before capture. `oracle.py`
  agrees with all paragraph lengths. The stale-source control against
  `96711ac69` rejects the changed Reference Map input. A fresh mdBook rebuild
  reproduces the capture; .5.2 and .5.3 retain the uncompleted visual/repair work.
- [x] **NO REGRESSION** — `mdbook build docs/book -d
  .artifacts/paragraph-spacing-book` succeeds before both census runs.
  The book sources, examples and theme configuration are unchanged.
  `knowledge-map/scripts/check_knowledge_map.sh`: `knowledge-map: OK`.
  No browser, server, HIAL capture or full CI was started by this leaf.
