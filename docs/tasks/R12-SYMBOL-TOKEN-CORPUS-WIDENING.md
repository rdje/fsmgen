# R12-SYMBOL-TOKEN-CORPUS-WIDENING: Symbol-Token Corpus Widening

## Metadata

- Tree ID: `R12-SYMBOL-TOKEN-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused symbol-definition identifier and scalar-token failures
into the maintained expected-failure regression corpus with stable diagnostics
and public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new symbol identifier or enum value syntax.
- Do not alter supported `+constants`, `+define`, `+params`, or `+enums`
  entries.
- Do not cover empty sections, malformed entry structure, unresolved values,
  parameter dependency graphs, or aggregate parameter expressions in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected symbol-token rejection families
  into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-SYMBOL-TOKEN-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for symbol identifier and enum scalar-token failures`
  Children: `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1`, `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2`

- ID: `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the symbol-token corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1: select symbol-token widening`

- ID: `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for malformed symbol identifiers and enum scalar values`
  Acceptance: `named fixtures/catalog entries cover malformed +constants, +define, and +params identifiers plus non-scalar +enums member values with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused symbol-token tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2: widen symbol-token corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2` shipped the selected symbol-token corpus widening. |

## Decisions

- `2026-05-20`: Selected malformed `+constants`, `+define`, and `+params`
  identifiers plus non-scalar `+enums` member values as the next R12 corpus
  subset because each is a user-visible token-boundary diagnostic with focused
  coverage but no maintained expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused symbol-token tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1` | `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1: select symbol-token widening` | Selection leaf; no compiler behavior changed. |
| `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2` | `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2: widen symbol-token corpus` | Adds four maintained symbol-token expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected symbol-token corpus widening and closed
  the task tree.
