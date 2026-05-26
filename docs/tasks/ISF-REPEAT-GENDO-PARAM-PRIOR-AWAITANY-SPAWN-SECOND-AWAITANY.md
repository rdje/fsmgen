# ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY: Static-Parameter Generated Do Prior AwaitAny Then Spawn And Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the static-parameter generated-do analogue of the repeated-observation
prior-observation do-then-spawn widening: a repeat directly inside a
top-level `when` body or top-level `switch` branch may run generated spawns,
observe one done pulse through a multi-pending `(await_any done)`, run
generated blocking `(do child (params ...))`, start one or more later
generated nested spawns, observe a second multi-pending `(await_any done)`,
and still drain every outstanding generated spawn through a mandatory
same-body `(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not extend the second post-spawn `await_any` shape to bound
  `(do child (params ...) (bind ...))` or same-domain generated `do`; those
  variants need separate leaves.
- Do not allow missing same-body `(await_all done)` after the second
  post-spawn observation.
- Do not change generated-child naming, generated-top parameter override
  semantics, generated-top input/output binding handoff semantics, domain
  metadata semantics, CDC behavior, cross-domain activation, deeper
  branch/loop nesting, or broader outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: generated spawns, prior multi-pending `(await_any
  done)`, static-parameter generated blocking `(do child (params ...))`,
  later generated `(spawn ...)`, second post-spawn multi-pending
  `(await_any done)`, and same-body `(await_all done)` before nested repeat
  re-entry.
- The prior and second `await_any` clauses observe pending generated children
  without clearing the outstanding generated-spawn set.
- The generated `do` waits for its deterministic generated do instance's fresh
  done handoff before the later generated spawn starts.
- Static generated-top parameter overrides remain scoped to the generated do
  instance and are preserved in generated instance metadata and top emission.
- The final same-body `await_all` drains generated spawns from both sides of
  the generated `do` before the nested repeat check can loop.
- Missing-drain, bound generated-do, same-domain generated-do, cross-domain,
  and unsupported nested repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
  Status: `done`
  Goal: `Ship static-parameter generated do after prior await_any followed by generated spawn, second await_any, and same-body drain.`
  Children: `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch static-parameter generated-do prior-await_any then spawn plus second await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior and second await_any observations, generated do done-handoff ordering, static parameter override preservation, later generated spawn scheduling, generated-instance metadata, and mandatory-drain semantics while missing-drain, bound/domain generated-do variants, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused scheduler/doc audits; live path audits; mdBook build; stale-doc scan; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1: ship static generated-do second awaitany drain`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `done` | Shipped the static-parameter generated-do analogue of the local-do and plain generated-child prior-observation second-await_any shapes. |

## Decisions

- `2026-05-26`: Select only static-parameter generated `(do child (params ...))`
  for the next repeated-observation prior-`await_any` do-then-spawn lifetime
  proof. Binding handoffs and domain metadata remain separate leaves.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1120-isf-public-live-document-path-audit.t t/1303-isf-public-live-book-paths-audit.t`; stale-doc `rg`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `PASS; focused tests Files=3, Tests=713; live path audits Files=2, Tests=29; broader gate Files=275, Tests=1932` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1: ship static generated-do second awaitany drain` | `task-scoped commit subject` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the
  static-parameter generated-do prior-`await_any` then generated-spawn plus
  second post-spawn `await_any` before same-body `await_all` drain analogue.
- `2026-05-26`: Shipped the static-parameter generated-do prior-`await_any`
  then generated-spawn plus second post-spawn `await_any` before mandatory
  same-body `await_all` drain subset for branch-contained top-level `when`
  bodies and `switch` branches. Bound and same-domain generated-do second
  post-spawn `await_any` prior-observation variants remain deferred.
