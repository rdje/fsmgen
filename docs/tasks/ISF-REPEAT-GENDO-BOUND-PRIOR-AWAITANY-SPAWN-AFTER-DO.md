# ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO: Bound Generated Do After AwaitAny Then Spawn Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next specialized generated-do prior-observation spawn-after-do
widening: a repeat directly inside a top-level `when` body or top-level
`switch` branch may run generated spawns, observe one done pulse through a
multi-pending `(await_any done)`, run bound generated blocking
`(do child (params ...) (bind ...))`, then start one or more additional
generated nested spawns before the mandatory same-body `(await_all done)`
drain.

## Non-Goals

- Keep same-domain generated `do` before the later generated spawn after a
  prior multi-pending `await_any` deferred to a separate leaf.
- Do not allow a second multi-pending `(await_any done)` after the later
  generated spawn before the mandatory same-body drain.
- Do not allow missing same-body `(await_all done)` after the later generated
  spawn.
- Do not change generated-child naming, generated-top parameter override
  semantics, generated-top input/output binding handoff semantics, domain
  metadata, CDC behavior, cross-domain activation, deeper branch/loop
  nesting, or broader outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: generated spawns, prior multi-pending `(await_any
  done)`, bound generated blocking `(do child (params ...) (bind ...))`,
  later generated `(spawn ...)`, and same-body `(await_all done)` before
  nested repeat re-entry.
- The prior `await_any` observes any pending generated child without clearing
  the outstanding generated-spawn set.
- The bound generated `do` waits for its deterministic generated do instance's
  fresh done handoff before the later generated spawn starts.
- The generated do records the static parameter override and generated-top
  input/output binding handoffs once for its generated-top instance, and the
  later generated spawn keeps its own static generated-child instance
  identity.
- The final same-body `await_all` drains generated spawns from both sides of
  the bound generated `do` before the nested repeat check can loop.
- Same-domain, repeated-observation, missing-drain, cross-domain, and
  unsupported nested repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO`
  Status: `done`
  Goal: `Ship bound generated do after prior await_any followed by generated spawn and same-body drain.`
  Children: `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`

- ID: `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`
  Status: `done`
  Goal: `Implement and document the when/switch bound generated-do prior-await_any then spawn analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior await_any observation, generated do done-handoff ordering, parameter override and binding handoff preservation, later generated spawn scheduling, and mandatory-drain semantics while same-domain generated-do, repeated-observation, missing-drain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; prove -Iperl t/1215-isf-spawn-parameter-binding.t; focused book/public audits; live-doc audits; broader repeat/child regression; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `done` | Shipped the bound generated-do prior-observation spawn-after-do analogue. |

## Decisions

- `2026-05-26`: Select only static-parameter generated `(do child (params
  ...) (bind ...))` for this prior-`await_any` do-then-spawn lifetime proof.
  Same-domain metadata remains a separate leaf so declared ownership grouping
  does not mix with binding-handoff lifetime proof.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1120-isf-public-live-document-path-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `PASS`; focused behavior `Files=1, Tests=88`; focused doc audits `Files=2, Tests=569`; public/book audits `Files=4, Tests=573`; live-doc audits `Files=4, Tests=598`; repeat/child regression `Files=4, Tests=102`; ISF CI `Files=275, Tests=1876` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1: ship bound prior-awaitany spawn-after-do` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the bound generated
  do prior-`await_any` then generated-spawn before same-body `await_all` drain
  analogue.
- `2026-05-26`: Completed the selected leaf; bound generated `do` with static
  params and generated-top input/output binding handoffs may now follow a
  prior multi-pending `await_any` and precede a later generated spawn before
  mandatory same-body `await_all` in the documented top-level
  branch-contained subsets.
