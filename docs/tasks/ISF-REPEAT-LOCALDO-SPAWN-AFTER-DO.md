# ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO: Local Do Then Spawn Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next bounded repeat-body child-activation widening: a repeat directly
inside a top-level `when` body or top-level `switch` branch may run a local
blocking `do` while generated nested spawns are pending, then start one or
more additional generated nested spawns before the mandatory same-body
`(await_all done)` drain.

## Non-Goals

- Keep new spawn after generated-child, static-parameter, bound, or
  same-domain generated `do` before the drain deferred to their own
  generated-do follow-up leaves.
- Do not allow a new spawn after any `do` once a multi-pending `(await_any
  done)` observation is active.
- Do not allow missing drains, single-pending post-do `await_any` widening,
  cross-domain activation, deeper branch/loop nesting, or broader
  outstanding-child lifetime semantics.
- Do not change generated child naming, generated top parameter/binding
  behavior, local child start/done handoff naming, or schedule-report key
  families outside the selected local-do spawn-after-do analogue.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: initial generated `(spawn ...)`, local `(do child)`,
  later generated `(spawn ...)`, and same-body `(await_all done)` before nested
  repeat re-entry.
- The local do waits for its local child's fresh done pulse before the later
  generated spawn starts.
- The later generated spawn is added to the outstanding generated-spawn set,
  and the same-body `await_all` drains both the pre-do and post-do generated
  spawns before the nested repeat check can loop.
- Existing rejection coverage for generated-do spawn-after-do, missing drains,
  post-`await_any` spawn-before-drain, cross-domain activation, and unsupported
  nested repeat shapes remains intact.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO`
  Status: `done`
  Goal: `Ship local do followed by generated spawn before same-body drain.`
  Children: `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1`

- ID: `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1`
  Status: `done`
  Goal: `Implement and document the when/switch local-do spawn-after-do analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, local done ordering, later generated spawn scheduling, and mandatory-drain semantics while generated-do and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215; book/public audits; broader repeat/child regression; ISF CI regression; mdBook build; git diff check`
  Commit: `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1: ship local do spawn-before-drain`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1` | `done` | Shipped the branch-contained local-do-then-later-spawn analogue and kept generated-do spawn-after-do deferred. |

## Decisions

- `2026-05-26`: Select only the branch-contained local-do spawn-after-do
  analogue. Local do has no generated instance metadata or generated-top
  payload handoffs, so the slice can prove outstanding-child lifetime without
  mixing in generated-do ownership and binding semantics.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; book/public syntax checks; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1` | `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1: ship local do spawn-before-drain` | Shipped and closed. |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the local-do
  spawn-after-do before same-body `await_all` drain analogue.
- `2026-05-26`: Shipped branch-contained local do followed by later generated
  spawn before mandatory same-body `await_all` drain; closed the task tree.
