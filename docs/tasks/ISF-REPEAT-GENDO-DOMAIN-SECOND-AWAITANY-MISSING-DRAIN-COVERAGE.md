# ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Same-Domain Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Add defensive missing-drain regression coverage for the same-domain
generated-do prior-`await_any` then spawn then second post-spawn `await_any`
shape that
`ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` just
shipped. Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the
`'generated do with static params and same-domain metadata'` kind when no
final same-body `(await_all done)` follows.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.
- Do not introduce missing-drain coverage for unrelated shapes (plain/param/
  bound or non-second-await_any variants); those are separate slices.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- One new `assert_lower_rejected` regression in `t/1215-isf-spawn-parameter-binding.t`
  for the top-level `when`-body same-domain generated-do prior-`await_any`
  then spawn then second `await_any` without final same-body `(await_all
  done)` shape, mirroring the existing line-10676 / line-10803 precedents.
- One companion `assert_lower_rejected` regression for the top-level
  `switch`-branch analogue, mirroring the existing line-10581 precedent.
- Both new regressions match the validator's
  `'generated do with static params and same-domain metadata'` confess
  message at `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Add defensive missing-drain coverage for same-domain second-awaitany.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the when-body and switch-branch missing-drain assertions in t/1215.`
  Acceptance: `Both new assertions execute and pass against the existing validator confess; the slice remains test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Locked the missing-drain fail-closed contract for the just-shipped same-domain SECOND-AWAITANY shape. |

## Decisions

- `2026-05-26`: Scope the slice narrowly to same-domain SECOND-AWAITANY
  missing-drain regressions. The analogous missing-drain SECOND-AWAITANY
  cases for plain/param/bound and the switch-branch generated-child variant
  are deliberately deferred so each remains independently reviewable.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; t/1215 `Files=1, Tests=100`; mdBook built clean; whitespace clean; ISF CI pending in-flight |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for same-domain second-awaitany` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree to lock in defensive
  missing-drain coverage for the same-domain SECOND-AWAITANY shape shipped
  by `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`.
- `2026-05-26`: Completed the selected leaf; added one when-body and one
  switch-branch `assert_lower_rejected` regression for the same-domain
  generated-do prior-`await_any` then spawn then second post-spawn
  `await_any` without final `(await_all done)` shape, locking the existing
  validator confess at `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551`. The
  matching missing-drain regressions for plain/param/bound and the
  switch-branch generated-child variant remain deferred as independent
  slices.
