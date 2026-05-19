# MDBOOK-PARAGRAPH-SPACING: Normalize mdBook Paragraph Separation

## Metadata

- Tree ID: `MDBOOK-PARAGRAPH-SPACING`
- Status: `done`
- Roadmap lane: `project documentation`
- Created: `2026-05-19`
- Last updated: `2026-05-19`
- Owner: repo-local workflow

## Goal

Make the mdBook source easier to read and review by ensuring prose
paragraphs are separated by one blank line instead of running together as
large text blobs.

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
- `mdbook build docs/book` passes.
- A focused diff review confirms the slice is formatting-only.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-PARAGRAPH-SPACING`
  Status: `done`
  Goal: `Normalize mdBook prose paragraph separation without changing technical content.`
  Children: `MDBOOK-PARAGRAPH-SPACING.1`, `MDBOOK-PARAGRAPH-SPACING.2`, `MDBOOK-PARAGRAPH-SPACING.3`, `MDBOOK-PARAGRAPH-SPACING.4`

- ID: `MDBOOK-PARAGRAPH-SPACING.1`
  Status: `completed`
  Goal: `Create task-tree ownership and define the paragraph-spacing cleanup scope.`
  Acceptance: `Create this task tree, register it in docs/TASK_TREE.md, identify chapter 12 and chapter 14 as required audit targets, and keep implementation deferred to the next leaf.`
  Verification: `mdbook build docs/book; git diff --check; whitespace-normalized mdBook source comparison against HEAD`
  Commit: `this commit: MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree`

- ID: `MDBOOK-PARAGRAPH-SPACING.2`
  Status: `completed`
  Goal: `Normalize obvious mdBook prose paragraph blobs.`
  Acceptance: `Review the mdBook source, starting with chapter 12 and chapter 14, and insert one blank line between adjacent prose paragraphs where missing. Preserve code fences, tables, lists, examples, headings, and all technical wording. Update live docs with the formatting-only result.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: MDBOOK-PARAGRAPH-SPACING.2: normalize book paragraph spacing`

- ID: `MDBOOK-PARAGRAPH-SPACING.3`
  Status: `completed`
  Goal: `Reopen the cleanup for rendered-HTML list-item blobs.`
  Acceptance: `Record that the first cleanup fixed ordinary paragraph boundaries but left long Markdown list items that render as single HTML list-item blobs, and select a follow-up leaf with rendered-HTML validation.`
  Verification: `mdbook build docs/book; rendered HTML audit identifies long list-item blobs`
  Commit: `this commit: MDBOOK-PARAGRAPH-SPACING.3: reopen rendered HTML blob cleanup`

- ID: `MDBOOK-PARAGRAPH-SPACING.4`
  Status: `completed`
  Goal: `Split long rendered HTML list-item prose blobs.`
  Acceptance: `Audit the built mdBook HTML for long prose paragraphs and list items, split the remaining long list-item prose blobs into list-contained paragraphs without changing technical wording, preserve fences/tables/lists/examples/headings, and validate the rendered HTML no longer has obvious long blobs in the reported chapters.`
  Verification: `mdbook build docs/book; rendered HTML audit for long paragraphs and long list items; whitespace-normalized source comparison against HEAD; git diff --check`
  Commit: `this commit: MDBOOK-PARAGRAPH-SPACING.4: split rendered book prose blobs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Rendered HTML prose-blob cleanup is complete and validated across the built book. |

## Decisions

- `2026-05-19`: Treat the user-reported readability problem as a
  formatting-only mdBook source cleanup. Chapter 12 and chapter 14 are
  mandatory audit targets because the user called them out directly.
- `2026-05-19`: Reopened after rendered HTML review showed that ordinary
  Markdown paragraph splitting did not affect long list items, which still
  render as single `<li>` blobs unless list-contained paragraph breaks are
  inserted.

## Open Questions

- None for `.4`; the remaining work is a rendered-HTML formatting fix.

## Blockers

- None.

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
| `MDBOOK-PARAGRAPH-SPACING.1` | `this commit: MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree` | `creates ownership before book-source formatting edits` |
| `MDBOOK-PARAGRAPH-SPACING.2` | `this commit: MDBOOK-PARAGRAPH-SPACING.2: normalize book paragraph spacing` | `formatting-only mdBook source readability cleanup` |
| `MDBOOK-PARAGRAPH-SPACING.3` | `this commit: MDBOOK-PARAGRAPH-SPACING.3: reopen rendered HTML blob cleanup` | `reopens the task tree for HTML-visible list-item blobs` |
| `MDBOOK-PARAGRAPH-SPACING.4` | `this commit: MDBOOK-PARAGRAPH-SPACING.4: split rendered book prose blobs` | `validates the generated HTML directly` |

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
