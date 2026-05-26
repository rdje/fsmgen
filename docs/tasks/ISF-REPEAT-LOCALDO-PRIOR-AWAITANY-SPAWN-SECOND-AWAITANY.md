# ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY: Local Do Prior AwaitAny Then Spawn And Second AwaitAny

## Metadata

- Tree ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the first repeated-observation prior-observation do-then-spawn widening:
a repeat directly inside a top-level `when` body or top-level `switch` branch
may run generated spawns, observe one done pulse through a multi-pending
`(await_any done)`, run local blocking `(do child)`, start one or more later
generated nested spawns, observe a second multi-pending `(await_any done)`,
and still drain every outstanding generated spawn through a mandatory
same-body `(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not extend the second post-spawn `await_any` shape to plain generated-
  child, static-parameter generated, bound generated, or same-domain generated
  `do`; those variants need separate leaves.
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
  done)`, local blocking `(do child)`, later generated `(spawn ...)`, second
  post-spawn multi-pending `(await_any done)`, and same-body `(await_all
  done)` before nested repeat re-entry.
- The prior and second `await_any` clauses observe pending generated children
  without clearing the outstanding generated-spawn set.
- The local `do` waits for its fresh local child done pulse before the later
  generated spawn starts.
- The final same-body `await_all` drains generated spawns from both sides of
  the local `do` before the nested repeat check can loop.
- Missing-drain, generated-do variants, cross-domain, and unsupported nested
  repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY`
  Status: `done`
  Goal: `Ship local do after prior await_any followed by generated spawn, second await_any, and same-body drain.`
  Children: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`

- ID: `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch local-do prior-await_any then spawn plus second await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior and second await_any observations, local do done-pulse ordering, later generated spawn scheduling, and mandatory-drain semantics while missing-drain, generated-do variants, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; prove -Iperl t/1215-isf-spawn-parameter-binding.t; focused doc audits; focused book/public audits; live-doc audits; broader repeat/child regression; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `done` | Shipped the branch-contained local-do prior-awaitany do-then-spawn plus second awaitany analogue. |

## Decisions

- `2026-05-26`: Select local `(do child)` for the first repeated-observation
  prior-`await_any` do-then-spawn lifetime proof. Generated-child,
  static-parameter, bound, same-domain, cross-domain, CDC, and broader
  outstanding-child lifetime behavior remain outside this slice.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1120-isf-public-live-document-path-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `PASS`; focused behavior `Files=1, Tests=92`; focused doc audits `Files=2, Tests=591`; public/book audits `Files=4, Tests=595`; live-doc audits `Files=4, Tests=620`; repeat/child regression `Files=4, Tests=106`; ISF CI `Files=275, Tests=1902` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` | `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1: ship local second awaitany drain` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the local-do
  prior-`await_any` then generated-spawn plus second post-spawn `await_any`
  before same-body `await_all` drain analogue.
- `2026-05-26`: Completed the selected leaf; branch-contained local `do`
  after a prior multi-pending `await_any` may now start a later generated
  spawn, run a second post-spawn multi-pending `await_any`, and then drain
  pre-do and post-do generated spawns through mandatory same-body
  `await_all` in the documented top-level `when` and `switch` subsets.
