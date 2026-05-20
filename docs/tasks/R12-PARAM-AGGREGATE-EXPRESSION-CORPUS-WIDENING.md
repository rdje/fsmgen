# R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING: Parameter Aggregate-Expression Corpus Widening

## Metadata

- Tree ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused aggregate `+params` expression failures into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new aggregate parameter expression operators.
- Do not alter supported scalar or aggregate parameter declarations.
- Do not cover parameter dependency cycles, duplicate parameter declarations,
  unresolved parameter values, or ambiguous bare bitstring parameter values in
  this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected aggregate `+params` expression
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for aggregate +params expression failures`
  Children: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1`, `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2`

- ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the aggregate parameter-expression corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1: select aggregate parameter-expression widening`

- ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for aggregate +params expression operand, shape, overflow, underflow, and divide-by-zero failures`
  Acceptance: `named fixtures/catalog entries cover aggregate +params expression mixed operands, shape mismatches, arithmetic overflow, underflow, and divide-by-zero with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused symbol-definition tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2: widen aggregate parameter-expression corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2` shipped the selected aggregate parameter-expression corpus widening. |

## Decisions

- `2026-05-20`: Selected aggregate `+params` expression operand, shape,
  overflow, underflow, and divide-by-zero failures as the next R12 corpus
  subset because each is a user-visible parameter expression diagnostic with
  focused coverage but no maintained expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused symbol-definition tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1: select aggregate parameter-expression widening` | Selection leaf; no compiler behavior changed. |
| `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2: widen aggregate parameter-expression corpus` | Adds six maintained aggregate parameter-expression expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected aggregate parameter-expression corpus
  widening and closed the task tree.
