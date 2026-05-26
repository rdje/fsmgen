# ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Static-Parameter Before Post-Do AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Add defensive missing-drain regression coverage for the static-parameter
generated `(do worker (params ...))` before post-do multi-pending
`(await_any done)` without final same-body `(await_all done)` drain shape.
Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated do with
static params'` kind when no final drain follows the post-do observation.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.

## Acceptance Criteria

- One when-body and one switch-branch `assert_lower_rejected` regression in
  `t/1215-isf-spawn-parameter-binding.t` for the static-parameter
  generated do before post-do multi-pending await_any without final drain
  shape.
- Both regressions match the `'generated do with static params'` confess at
  `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Add defensive missing-drain coverage for static-parameter before post-do await_any.`
  Children: `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert when-body and switch-branch missing-drain assertions in t/1215.`
  Acceptance: `Both new assertions pass against the existing validator confess; test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Locked the missing-drain fail-closed contract for the shipped static-parameter BEFORE-POST-DO-AWAITANY shape. |

## Decisions

- `2026-05-27`: Scope narrowly to static-parameter BEFORE-POST-DO-AWAITANY
  missing-drain regressions on both branch-contained subsets.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; `Files=1, Tests=100`; mdBook clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for static-parameter before post-do await_any` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created and completed R14 task tree adding when-body and
  switch-branch `assert_lower_rejected` regressions for the static-parameter
  generated `(do worker (params ...))` before post-do multi-pending
  `(await_any done)` without final `(await_all done)` drain shape, locking
  the existing validator confess at `LoweringIR.pm:6551`.
