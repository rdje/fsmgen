# ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY: Same-Domain Generated Do Prior AwaitAny Then Spawn And Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the same-domain generated-do analogue of the repeated-observation
prior-observation do-then-spawn widening: a repeat directly inside a
top-level `when` body or top-level `switch` branch may run generated spawns,
observe one done pulse through a multi-pending `(await_any done)`, run
generated blocking
`(do child (params ...) [(bind ...)] (domain NAME))`, start one or more later
generated nested spawns, observe a second multi-pending `(await_any done)`,
and still drain every outstanding generated spawn through a mandatory
same-body `(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not allow missing same-body `(await_all done)` after the second
  post-spawn observation.
- Do not extend cross-domain activation, deeper branch/loop nesting, CDC
  behavior, or broader outstanding-child lifetime policy.
- Do not change generated-child naming, static parameter override semantics,
  generated-top input/output binding handoff names, or declared-domain
  ownership metadata semantics for the generated do instance.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: generated spawns, prior multi-pending `(await_any
  done)`, same-domain static-parameter generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))`, later generated
  `(spawn ...)`, second post-spawn multi-pending `(await_any done)`, and
  same-body `(await_all done)` before nested repeat re-entry.
- The prior and second `await_any` clauses observe pending generated children
  without clearing the outstanding generated-spawn set.
- The generated `do` waits for its deterministic generated do instance's fresh
  done handoff before the later generated spawn starts.
- Static generated-top parameter overrides, optional generated-top
  input/output binding handoffs, and declared same-domain ownership metadata
  remain scoped to the generated do instance and are preserved in generated
  instance metadata, generated top emission, schedule reports, and clock-
  domain partition reports.
- The final same-body `await_all` drains generated spawns from both sides of
  the generated `do` before the nested repeat check can loop.
- Missing-drain, cross-domain activation, deeper branch/loop nesting, CDC,
  and unsupported nested repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
  Status: `done`
  Goal: `Ship same-domain generated do after prior await_any followed by generated spawn, second await_any, and same-body drain.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch same-domain generated-do prior-await_any then spawn plus second await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior and second await_any observations, generated do done-handoff ordering, static parameter override / binding handoff / domain metadata preservation, later generated spawn scheduling, generated-instance metadata, clock-domain partition grouping, and mandatory-drain semantics while missing-drain, cross-domain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215, t/1305, t/1307; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `done` | Shipped the branch-contained same-domain generated-do prior-observation second-`await_any` analogue. |

## Decisions

- `2026-05-26`: Treat declared `(domain NAME)` as static metadata that
  outlives both observation windows: it is a frontend property of the
  generated child definition and the generated `do` instance, not a runtime
  state that the multi-pending observation could invalidate. The bound /
  param shapes already preserve static parameter overrides and generated-top
  binding handoffs through both observations; declared same-domain ownership
  is the same lifetime class.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS`; focused suite `Files=3, Tests=739`; mdBook built clean; ISF CI `Files=275, Tests=1958`; whitespace clean |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1: ship same-domain generated-do second awaitany drain` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the same-domain
  generated do prior-`await_any` then generated-spawn plus second post-spawn
  `await_any` before same-body `await_all` drain analogue. The bound,
  static-parameter, and plain generated-child analogues have already shipped
  in `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`,
  `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`, and
  `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY` respectively.
- `2026-05-26`: Shipped the same-domain generated-do repeated-observation
  prior-observation analogue for top-level `when` body and top-level
  `switch` branch nested repeats. The validator allow-list at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6470` now includes
  `'generated do with static params and same-domain metadata'`; declared
  ownership metadata is preserved across the multi-pending window because
  it is static frontend metadata bound to the generated child definition
  and the generated do instance. Missing same-body `await_all` drain,
  cross-domain activation, deeper branch/loop nesting, CDC behavior, and
  broader outstanding-child lifetime semantics remain fail-closed.
