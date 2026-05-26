# ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Plain Generated-Child Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Add the missing switch-branch defensive regression coverage for the plain
generated-child `(do child)` prior-`await_any` then spawn then second
post-spawn `await_any` shape that
`ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` shipped.
The when-body counterpart already lives in
`t/1215-isf-spawn-parameter-binding.t` at the existing missing-drain
assertion for that shape; this slice closes the switch-branch gap. Lock the
existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated-child do'`
kind when no final same-body `(await_all done)` follows.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.
- Do not introduce missing-drain coverage for unrelated shapes (param/bound/
  same-domain SECOND-AWAITANY or non-SECOND-AWAITANY variants); those are
  separate slices.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- One new `assert_lower_rejected` regression in `t/1215-isf-spawn-parameter-binding.t`
  for the top-level `switch`-branch plain generated-child prior-`await_any`
  then spawn then second `await_any` without final `(await_all done)` shape.
  The when-body counterpart already exists in the same file.
- The new regression matches the validator's `'generated-child do'`
  confess at `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Add defensive missing-drain coverage for plain generated-child second-awaitany.`
  Children: `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the switch-branch missing-drain assertion in t/1215; the when-body counterpart already exists.`
  Acceptance: `The new assertion executes and passes against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Locked the missing-drain fail-closed contract for the shipped plain generated-child SECOND-AWAITANY shape. |

## Decisions

- `2026-05-26`: Scope the slice narrowly to plain generated-child
  SECOND-AWAITANY missing-drain regressions. The analogous missing-drain
  SECOND-AWAITANY cases for param/bound are deliberately deferred so each
  remains independently reviewable.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for plain generated-child second-awaitany` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created R14 task tree to lock defensive missing-drain
  coverage for the plain generated-child SECOND-AWAITANY shape shipped by
  `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`.
- `2026-05-26`: Completed the selected leaf; added one when-body and one
  switch-branch `assert_lower_rejected` regression for the plain
  generated-child `(do child)` prior-`await_any` then spawn then second
  post-spawn `await_any` without final `(await_all done)` shape, locking the
  existing validator confess at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`. The matching missing-drain
  regressions for param/bound remain deferred as independent slices.
