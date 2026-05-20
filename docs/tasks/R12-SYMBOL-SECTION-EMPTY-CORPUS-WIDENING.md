# R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING: Empty Symbol-Section Corpus Widening

## Metadata

- Tree ID: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused empty symbol-definition section failures into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new `+constants`, `+define`, `+params`, or `+enums` syntax.
- Do not alter supported symbol-definition entries.
- Do not claim all symbol-definition behavior is exhausted; this tree covers
  only empty section/directive rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected empty symbol-definition section
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for empty symbol-definition section failures`
  Children: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1`, `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2`

- ID: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the empty symbol-section corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1: select empty symbol-section widening`

- ID: `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for empty +constants, +define, +params, and +enums forms`
  Acceptance: `named fixtures/catalog entries cover empty symbol-definition sections with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2` | `pending` | Focused tests already cover empty symbol-definition sections; the maintained corpus does not yet carry them as stable support-accounting entries. |

## Decisions

- `2026-05-20`: Selected empty `+constants`, `+define`, `+params`, and
  `+enums` forms as the next R12 corpus subset because each is a user-visible
  symbol-section diagnostic with focused coverage but no maintained
  expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1` | `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1: select empty symbol-section widening` | Selection leaf; no compiler behavior changed. |
| `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2` | `pending` | Implementation leaf pending. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
