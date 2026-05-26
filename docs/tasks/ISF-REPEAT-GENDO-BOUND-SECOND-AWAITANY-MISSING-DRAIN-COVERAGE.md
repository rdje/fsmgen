# ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Bound Generated Do Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Add defensive missing-drain regression coverage for the bound generated
`(do child (params ...) (bind ...))` prior-`await_any` then spawn then
second post-spawn `await_any` shape that
`ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` shipped.
Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the
`'generated do with static params and bindings'` kind when no final
same-body `(await_all done)` follows.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.
- Do not introduce missing-drain coverage for unrelated shapes
  (plain/param/same-domain SECOND-AWAITANY or non-SECOND-AWAITANY variants).

## Acceptance Criteria

- One new `assert_lower_rejected` regression in `t/1215-isf-spawn-parameter-binding.t`
  for the top-level `when`-body bound generated
  `(do child (params ...) (bind ...))` prior-`await_any` then spawn then
  second `await_any` without final `(await_all done)` shape.
- One companion `assert_lower_rejected` regression for the top-level
  `switch`-branch analogue.
- Both new regressions match the validator's
  `'generated do with static params and bindings'` confess at
  `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Add defensive missing-drain coverage for bound generated-do second-awaitany.`
  Children: `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the when-body and switch-branch missing-drain assertions in t/1215.`
  Acceptance: `Both new assertions execute and pass against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Locked the missing-drain fail-closed contract for the shipped bound SECOND-AWAITANY shape. |

## Decisions

- `2026-05-26`: Scope the slice narrowly to bound SECOND-AWAITANY
  missing-drain regressions. With this slice, the SECOND-AWAITANY
  missing-drain matrix is complete across the local-do, plain
  generated-child, static-parameter, bound, and same-domain families.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for bound generated-do second-awaitany` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created R14 task tree to lock defensive missing-drain
  coverage for the bound generated-do SECOND-AWAITANY shape shipped by
  `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`.
- `2026-05-26`: Completed the selected leaf; added one when-body and one
  switch-branch `assert_lower_rejected` regression for the bound generated
  `(do child (params ...) (bind ...))` prior-`await_any` then spawn then
  second post-spawn `await_any` without final `(await_all done)` shape,
  locking the existing validator confess at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`. With this slice, the
  SECOND-AWAITANY missing-drain matrix is complete across the five
  generated-do families.
