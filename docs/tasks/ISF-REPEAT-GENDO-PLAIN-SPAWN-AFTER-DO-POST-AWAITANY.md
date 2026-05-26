# ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY: Plain Generated Do Then Spawn Then AwaitAny Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next branch-contained repeat widening: a repeat directly inside a
top-level `when` body or top-level `switch` branch may run a plain
generated-child blocking `(do child)` while generated nested spawns are
pending, then start one or more additional generated nested spawns, then run a
multi-pending `(await_any done)` observation, and finally drain all generated
spawns with a same-body `(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not allow the local-do, static-parameter generated-do, bound
  generated-do, or same-domain generated-do variants of do-then-spawn-
  then-`await_any`.
- Do not allow later spawn after a prior active multi-pending `(await_any done)`
  observation.
- Do not allow missing same-body `(await_all done)` after the post-spawn
  multi-pending `(await_any done)`.
- Do not change top-level repeat-body rules, deeper branch/loop nesting,
  generated child naming, parameter/binding/domain metadata semantics, CDC
  behavior, or broader outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: initial generated `(spawn ...)`, plain generated-child
  `(do child)`, later generated `(spawn ...)`, post-spawn multi-pending
  `(await_any done)`, and same-body `(await_all done)` before nested repeat
  re-entry.
- The generated do waits for its deterministic generated do instance's fresh
  done handoff before the later generated spawn starts.
- The post-spawn `await_any` observes either pre-do or post-do generated spawn
  without clearing the outstanding generated-spawn set.
- The final same-body `await_all` drains both pre-do and post-do generated
  spawns before the nested repeat check can loop.
- Existing rejection coverage for local, static-parameter, bound,
  same-domain, post-prior-`await_any`, missing-drain, cross-domain, and
  unsupported generated-do spawn-after-do forms remains intact.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY`
  Status: `done`
  Goal: `Ship plain generated-child do followed by generated spawn, post-spawn await_any, and same-body drain.`
  Children: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch plain generated-child do-then-spawn post-await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, generated do done ordering, later generated spawn scheduling, post-spawn await_any observation, and mandatory-drain semantics while local, static-parameter, bound, same-domain, missing-drain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215; book/public audits; broader repeat/child regression; ISF CI regression; mdBook build; git diff check`
  Commit: `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1: ship generated-child post-spawn awaitany`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `done` | Shipped the plain generated-child do-then-spawn post-`await_any` surface while keeping local and specialized generated-do variants deferred. |

## Decisions

- `2026-05-26`: Select only plain generated-child `do` for the first
  do-then-spawn post-`await_any` widening. Specialized generated-do and
  local-do variants need separate reviewable lifetime proofs.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass`; focused t/1215 `Files=1, Tests=72`; book/public audits `Files=3, Tests=358`; broader repeat/child regression `Files=4, Tests=86`; ISF CI regression `Files=275, Tests=1801` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1: ship generated-child post-spawn awaitany` | `pending commit` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the plain
  generated-child do-then-spawn post-`await_any` before same-body
  `await_all` drain analogue.
- `2026-05-26`: Shipped the plain generated-child do-then-spawn post-spawn
  `await_any` before same-body `await_all` drain analogue and closed the task
  tree.
