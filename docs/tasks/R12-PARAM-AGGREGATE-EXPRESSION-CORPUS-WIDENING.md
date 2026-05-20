# R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING: Parameter Aggregate-Expression Corpus Widening

## Metadata

- Tree ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING`
- Status: `active`
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
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for aggregate +params expression failures`
  Children: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1`, `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2`

- ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the aggregate parameter-expression corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1: select aggregate parameter-expression widening`

- ID: `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for aggregate +params expression operand, shape, overflow, underflow, and divide-by-zero failures`
  Acceptance: `named fixtures/catalog entries cover aggregate +params expression mixed operands, shape mismatches, arithmetic overflow, underflow, and divide-by-zero with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2` | `pending` | Promotes the already-focused aggregate parameter-expression diagnostics after ownership is committed. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1` | `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1: select aggregate parameter-expression widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
