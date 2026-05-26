# ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Static-Parameter Switch-Branch Spawn-After-Do

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Add the missing switch-branch defensive regression coverage for the
static-parameter generated `(do worker (params (WIDTH 16)))` after prior
multi-pending `await_any` then later generated spawn without final
same-body `(await_all done)` drain shape. The when-body counterpart already
lives in `t/1215-isf-spawn-parameter-binding.t` at line ~10714; this slice
closes the switch-branch gap. Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated do with
static params'` kind when no final same-body `(await_all done)` follows.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.

## Acceptance Criteria

- One new `assert_lower_rejected` regression in
  `t/1215-isf-spawn-parameter-binding.t` for the top-level `switch`-branch
  static-parameter generated `(do worker (params ...))` prior-`await_any`
  then spawn without final `(await_all done)` shape.
- The new regression matches the validator's `'generated do with static
  params'` confess at `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Close switch-branch SPAWN-AFTER-DO missing-drain gap for static-parameter generated-do.`
  Children: `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the switch-branch missing-drain assertion in t/1215.`
  Acceptance: `The new assertion executes and passes against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `done` | Closed the switch-branch SPAWN-AFTER-DO missing-drain gap for static-parameter generated-do. |

## Decisions

- `2026-05-26`: Scope narrowly to the switch-branch static-parameter
  SPAWN-AFTER-DO without-drain regression. With this slice, the
  SPAWN-AFTER-DO without-drain matrix is complete across all five
  generated-do families on both branch-contained subsets.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for static-parameter switch-branch spawn-after-do` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created R14 task tree to close the switch-branch
  SPAWN-AFTER-DO without-drain regression gap for static-parameter
  generated-do.
- `2026-05-26`: Completed the selected leaf; added one switch-branch
  `assert_lower_rejected` regression for the static-parameter generated
  `(do worker (params ...))` prior-`await_any` then later generated spawn
  without final same-body `(await_all done)` drain shape, locking the
  existing validator confess at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`. With this slice, the
  SPAWN-AFTER-DO without-drain matrix is complete across all five
  generated-do families on both branch-contained subsets.
