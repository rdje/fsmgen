# ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY: Generated-Child Do Prior AwaitAny Then Spawn And Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the plain generated-child analogue of the repeated-observation
prior-observation do-then-spawn widening: a repeat directly inside a
top-level `when` body or top-level `switch` branch may run generated spawns,
observe one done pulse through a multi-pending `(await_any done)`, run plain
generated-child blocking `(do child)`, start one or more later generated
nested spawns, observe a second multi-pending `(await_any done)`, and still
drain every outstanding generated spawn through a mandatory same-body
`(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not extend the second post-spawn `await_any` shape to static-parameter,
  bound, or same-domain generated `do`; those variants need separate leaves.
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
  done)`, plain generated-child blocking `(do child)`, later generated
  `(spawn ...)`, second post-spawn multi-pending `(await_any done)`, and
  same-body `(await_all done)` before nested repeat re-entry.
- The prior and second `await_any` clauses observe pending generated children
  without clearing the outstanding generated-spawn set.
- The generated-child `do` waits for its deterministic generated do
  instance's fresh done handoff before the later generated spawn starts.
- The final same-body `await_all` drains generated spawns from both sides of
  the generated-child `do` before the nested repeat check can loop.
- Missing-drain, specialized generated-do variants, cross-domain, and
  unsupported nested repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
  Status: `done`
  Goal: `Ship generated-child do after prior await_any followed by generated spawn, second await_any, and same-body drain.`
  Children: `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch generated-child prior-await_any then spawn plus second await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior and second await_any observations, generated do done-handoff ordering, later generated spawn scheduling, generated-instance metadata, and mandatory-drain semantics while missing-drain, specialized generated-do variants, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; prove -Iperl t/1215-isf-spawn-parameter-binding.t; prove -Iperl t/1305-isf-book-feature-matrix-audit.t; prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t; focused book/public audits; live-doc audits; broader repeat/child regression; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `done` | Shipped the branch-contained plain generated-child prior-awaitany do-then-spawn plus second awaitany analogue. |

## Decisions

- `2026-05-26`: Select only plain generated-child `(do child)` for the next
  repeated-observation prior-`await_any` do-then-spawn lifetime proof.
  Static parameter, binding, and domain metadata variants remain separate
  leaves.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1120-isf-public-live-document-path-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `PASS`; focused behavior `Files=1, Tests=94`; matrix audit `Files=1, Tests=397`; loop-body doc audit `Files=1, Tests=207`; public/book audits `Files=2, Tests=4`; live-doc audits `Files=4, Tests=633`; repeat/child regression `Files=4, Tests=108`; ISF CI `Files=275, Tests=1917` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1: ship generated-child second awaitany drain` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the plain
  generated-child prior-`await_any` then generated-spawn plus second
  post-spawn `await_any` before same-body `await_all` drain analogue.
- `2026-05-26`: Completed the selected leaf; branch-contained plain
  generated-child `do` after a prior multi-pending `await_any` may now start
  a later generated spawn, run a second post-spawn multi-pending
  `await_any`, and then drain pre-do and post-do generated spawns through
  mandatory same-body `await_all` in the documented top-level `when` and
  `switch` subsets.
