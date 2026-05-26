# ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Plain Generated-Child Before Post-Do AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Add defensive missing-drain regression coverage for the plain
generated-child `(do worker)` before post-do multi-pending `(await_any done)`
without final same-body `(await_all done)` drain shape that
`ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` (and precursors)
shipped. Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated-child do'`
kind when no final same-body `(await_all done)` follows the post-do
observation.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.

## Acceptance Criteria

- One new `assert_lower_rejected` regression in
  `t/1215-isf-spawn-parameter-binding.t` for the top-level `when`-body plain
  generated-child `(do worker)` before post-do multi-pending `(await_any
  done)` without final `(await_all done)` shape.
- One companion `assert_lower_rejected` regression for the top-level
  `switch`-branch analogue.
- Both regressions match the `'generated-child do'` confess at
  `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Add defensive missing-drain coverage for plain generated-child before post-do await_any.`
  Children: `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the when-body and switch-branch missing-drain assertions in t/1215.`
  Acceptance: `Both new assertions execute and pass against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Locked the missing-drain fail-closed contract for the shipped plain generated-child BEFORE-POST-DO-AWAITANY shape. |

## Decisions

- `2026-05-27`: Scope narrowly to plain generated-child BEFORE-POST-DO-AWAITANY
  missing-drain regressions on both branch-contained subsets. Param/bound/
  domain analogues remain as separate independent follow-up slices.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for plain generated-child before post-do await_any` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created R14 task tree to lock defensive missing-drain
  coverage for the plain generated-child BEFORE-POST-DO-AWAITANY shape.
- `2026-05-27`: Completed the selected leaf; added one when-body and one
  switch-branch `assert_lower_rejected` regression for the plain
  generated-child `(do worker)` before post-do multi-pending
  `(await_any done)` without final `(await_all done)` drain shape,
  locking the existing validator confess at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`.
