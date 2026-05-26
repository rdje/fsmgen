# ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE: Defensive Missing-Drain Coverage For Bound Before Post-Do AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Add the missing when-body defensive regression coverage for the bound
generated `(do worker (params ...) (bind ...))` before post-do
multi-pending `(await_any done)` without final same-body `(await_all done)`
drain shape. The switch-branch counterpart already lives in
`t/1215-isf-spawn-parameter-binding.t` at line ~12061; this slice closes
the symmetric when-body gap. Lock the existing validator confess at
`perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the `'generated do with
static params and bindings'` kind.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports, generated
  HDL, manifests, public API, or any user-visible surface.

## Acceptance Criteria

- One when-body `assert_lower_rejected` regression in
  `t/1215-isf-spawn-parameter-binding.t` for the bound generated `(do
  worker (params ...) (bind ...))` before post-do multi-pending
  `(await_any done)` without final `(await_all done)` shape. The switch
  counterpart already exists.
- The new regression matches the `'generated do with static params and
  bindings'` confess at `LoweringIR.pm:6551`.
- Live docs and roadmap status are updated.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE`
  Status: `done`
  Goal: `Close when-body BEFORE-POST-DO-AWAITANY missing-drain gap for bound generated-do.`
  Children: `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`

- ID: `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  Status: `done`
  Goal: `Insert the when-body missing-drain assertion in t/1215.`
  Acceptance: `The new assertion executes and passes against the existing validator confess; test-only.`
  Verification: `prove -Iperl t/1215-isf-spawn-parameter-binding.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `done` | Closed the when-body BEFORE-POST-DO-AWAITANY missing-drain gap for bound generated-do. |

## Decisions

- `2026-05-27`: Scope narrowly to bound BEFORE-POST-DO-AWAITANY when-body
  regression. The switch-branch counterpart already exists. Domain
  BEFORE-POST-DO-AWAITANY remains as the next independent follow-up slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `prove -Iperl t/1215`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; `Files=1, Tests=100`; mdBook clean; whitespace clean; ISF CI passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1` | `ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1: defensive missing-drain regression for bound when-body before post-do await_any` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created and completed R14 task tree adding the when-body
  `assert_lower_rejected` regression for the bound generated `(do worker
  (params ...) (bind ...))` before post-do multi-pending `(await_any done)`
  without final `(await_all done)` drain shape, locking the existing
  validator confess at `LoweringIR.pm:6551`.
