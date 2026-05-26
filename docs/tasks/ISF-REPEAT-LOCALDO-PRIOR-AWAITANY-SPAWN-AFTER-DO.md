# ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO: Local Do After AwaitAny Then Spawn Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next branch-contained repeat lifetime widening: a repeat directly
inside a top-level `when` body or top-level `switch` branch may run a
multi-pending `(await_any done)` observation while generated nested spawns
are pending, then run a local blocking `(do child)`, then start one or more
additional generated nested spawns, and finally drain all generated spawns
with a same-body `(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not allow generated-child, parameterized, bound, or same-domain
  generated `do` before the later generated spawn in this prior-`await_any`
  shape.
- Do not allow a second multi-pending `(await_any done)` after the later
  generated spawn before the mandatory same-body drain.
- Do not allow missing same-body `(await_all done)` after the later generated
  spawn.
- Do not change generated-child naming, generated-top metadata, CDC behavior,
  cross-domain activation, deeper branch/loop nesting, or broader
  outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: generated spawns, prior multi-pending `(await_any
  done)`, local blocking `(do child)`, later generated `(spawn ...)`, and
  same-body `(await_all done)` before nested repeat re-entry.
- The prior `await_any` observes any pending generated child without clearing
  the outstanding generated-spawn set.
- The local `do` waits for its fresh local child done pulse before the later
  generated spawn starts.
- The final same-body `await_all` drains the generated spawns from both sides
  of the local `do` before the nested repeat check can loop.
- Generated-do, repeated-observation, missing-drain, cross-domain, and
  unsupported nested repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO`
  Status: `done`
  Goal: `Ship local do after prior await_any followed by generated spawn and same-body drain.`
  Children: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`

- ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`
  Status: `done`
  Goal: `Implement and document the when/switch local-do prior-await_any then spawn analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior await_any observation, local done-pulse ordering, later generated spawn scheduling, and mandatory-drain semantics while generated-do, repeated-observation, missing-drain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215; book/public audits; broader repeat/child regression; ISF CI regression; mdBook build; git diff check`
  Commit: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1: ship local-do prior-awaitany spawn-after-do`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `done` | Shipped the local-do prior-`await_any` then generated-spawn surface while keeping generated-do variants and second-observation forms deferred. |

## Decisions

- `2026-05-26`: Select only local plain `(do child)` for this prior-
  `await_any` do-then-spawn lifetime proof. Generated-do metadata variants
  remain separate leaves.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass`; focused t/1215 `Files=1, Tests=82`; book/public audits `Files=3, Tests=377`; broader repeat/child regression `Files=4, Tests=96`; ISF CI regression `Files=275, Tests=1830` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1: ship local-do prior-awaitany spawn-after-do` | `pending commit` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the local-do
  prior-`await_any` then generated-spawn before same-body `await_all` drain
  analogue.
- `2026-05-26`: Shipped the local-do prior-`await_any` then generated-spawn
  before same-body `await_all` drain analogue and closed the task tree.
