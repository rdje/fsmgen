# MDBOOK-PARAGRAPH-SPACING: Normalize mdBook Paragraph Separation

## Metadata

- Tree ID: `MDBOOK-PARAGRAPH-SPACING`
- Status: `active`
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
- `mdbook build docs/book` passes.
- A focused diff review confirms the slice is formatting-only.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-PARAGRAPH-SPACING`
  Status: `active`
  Goal: `Normalize mdBook prose paragraph separation without changing technical content.`
  Children: `MDBOOK-PARAGRAPH-SPACING.1`, `MDBOOK-PARAGRAPH-SPACING.2`

- ID: `MDBOOK-PARAGRAPH-SPACING.1`
  Status: `completed`
  Goal: `Create task-tree ownership and define the paragraph-spacing cleanup scope.`
  Acceptance: `Create this task tree, register it in docs/TASK_TREE.md, identify chapter 12 and chapter 14 as required audit targets, and keep implementation deferred to the next leaf.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree`

- ID: `MDBOOK-PARAGRAPH-SPACING.2`
  Status: `active`
  Goal: `Normalize obvious mdBook prose paragraph blobs.`
  Acceptance: `Review the mdBook source, starting with chapter 12 and chapter 14, and insert one blank line between adjacent prose paragraphs where missing. Preserve code fences, tables, lists, examples, headings, and all technical wording. Update live docs with the formatting-only result.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MDBOOK-PARAGRAPH-SPACING.2` | `active` | Task-tree ownership is in place; the next slice performs the formatting-only mdBook cleanup. |

## Decisions

- `2026-05-19`: Treat the user-reported readability problem as a
  formatting-only mdBook source cleanup. Chapter 12 and chapter 14 are
  mandatory audit targets because the user called them out directly.

## Open Questions

- None for `.2`; obvious prose blobs can be corrected without changing
  technical content.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-19` | `MDBOOK-PARAGRAPH-SPACING.1` | `mdbook build docs/book`; `git diff --check` | `created task-tree ownership for the mdBook paragraph-spacing cleanup` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MDBOOK-PARAGRAPH-SPACING.1` | `this commit: MDBOOK-PARAGRAPH-SPACING.1: create book spacing task tree` | `creates ownership before book-source formatting edits` |

## Changelog

- `2026-05-19`: Created task tree and selected `.2` for the formatting-only
  mdBook paragraph-spacing cleanup.
