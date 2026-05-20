# R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING: Delayed-Pulse Target Corpus Widening

## Metadata

- Tree ID: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused delayed-pulse LHS target failures into the maintained
expected-failure regression corpus with stable diagnostics and public report
coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add support for indexed, sliced, aggregate, or deconstruct delayed
  pulse targets.
- Do not alter supported scalar delayed-pulse assignment behavior.
- Do not cover delayed-pulse RHS value failures in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected delayed-pulse LHS target rejection
  families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for delayed-pulse LHS target failures`
  Children: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1`, `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.2`

- ID: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the delayed-pulse target corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1: select delayed-pulse target widening`

- ID: `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for indexed and sliced delayed-pulse LHS targets`
  Acceptance: `named fixtures/catalog entries cover indexed, range-sliced, and pair-form indexed delayed-pulse LHS targets with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.2` | `pending` | Promotes the already-focused delayed-pulse target diagnostics after ownership is committed. |

## Decisions

- `2026-05-20`: Selected indexed, range-sliced, and pair-form indexed
  delayed-pulse LHS target failures as the next R12 corpus subset because the
  R8 boundary is behavior-shipped and focused, but the maintained
  expected-failure corpus currently accounts only for delayed-pulse RHS
  failures.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1` | `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1: select delayed-pulse target widening` | Selected delayed-pulse LHS target widening before implementation. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
