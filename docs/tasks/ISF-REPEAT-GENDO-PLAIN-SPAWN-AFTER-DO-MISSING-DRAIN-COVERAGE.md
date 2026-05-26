# ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Plain Generated-Child Switch-Branch Spawn-After-Do

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Add the missing switch-branch defensive regression coverage for the plain
generated-child `(do worker)` after prior multi-pending `await_any` then
later generated spawn without final same-body `(await_all done)` drain
shape. The when-body counterpart already lives in
`t/1215-isf-spawn-parameter-binding.t` at line ~10785; this slice closes
the switch-branch gap. Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated-child do'`
kind when no final same-body `(await_all done)` follows.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.
- Do not introduce missing-drain coverage for unrelated shapes.

## Acceptance Criteria

- One new `assert_lower_rejected` regression in
  `t/1215-isf-spawn-parameter-binding.t` for the top-level `switch`-branch
  plain generated-child `(do worker)` prior-`await_any` then spawn without
  final `(await_all done)` shape.
- The new regression matches the validator's `'generated-child do'`
  confess at `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Close switch-branch SPAWN-AFTER-DO missing-drain gap for plain generated-child.`
  Children: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the switch-branch missing-drain assertion in t/1215.`
  Acceptance: `The new assertion executes and passes against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `done` | Closed the switch-branch SPAWN-AFTER-DO missing-drain gap for plain generated-child. |

## Decisions

- `2026-05-26`: Scope narrowly to the switch-branch plain generated-child
  SPAWN-AFTER-DO without-drain regression. The when-body counterpart
  already exists at `t/1215` line ~10785, and the static-parameter
  switch-branch gap is deferred to a separate slice.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for plain generated-child switch-branch spawn-after-do` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created R14 task tree to close the switch-branch
  SPAWN-AFTER-DO without-drain regression gap for plain generated-child.
- `2026-05-26`: Completed the selected leaf; added one switch-branch
  `assert_lower_rejected` regression for the plain generated-child
  `(do worker)` prior-`await_any` then later generated spawn without final
  same-body `(await_all done)` drain shape, locking the existing validator
  confess at `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`. The static-parameter
  switch-branch SPAWN-AFTER-DO missing-drain gap remains as the next
  independently reviewable follow-up.
