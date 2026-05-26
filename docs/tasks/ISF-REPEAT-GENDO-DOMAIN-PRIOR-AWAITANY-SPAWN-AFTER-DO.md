# ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO: Same-Domain Generated Do After AwaitAny Then Spawn Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the final specialized generated-do prior-observation spawn-after-do
widening in this series: a repeat directly inside a top-level `when` body or
top-level `switch` branch may run generated spawns, observe one done pulse
through a multi-pending `(await_any done)`, run same-domain generated
blocking `(do child (params ...) [(bind ...)] (domain NAME))`, then start one
or more additional generated nested spawns before the mandatory same-body
`(await_all done)` drain.

## Non-Goals

- Do not allow a second multi-pending `(await_any done)` after the later
  generated spawn before the mandatory same-body drain.
- Do not allow missing same-body `(await_all done)` after the later generated
  spawn.
- Do not change generated-child naming, generated-top parameter override
  semantics, generated-top input/output binding handoff semantics, domain
  metadata semantics, CDC behavior, cross-domain activation, deeper
  branch/loop nesting, or broader outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: generated spawns, prior multi-pending `(await_any
  done)`, same-domain generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))`, later generated
  `(spawn ...)`, and same-body `(await_all done)` before nested repeat
  re-entry.
- The prior `await_any` observes any pending generated child without clearing
  the outstanding generated-spawn set.
- The same-domain generated `do` waits for its deterministic generated do
  instance's fresh done handoff before the later generated spawn starts.
- The generated do records the static parameter override, optional
  generated-top input/output binding handoffs, and declared same-domain
  ownership metadata once for its generated-top instance, and the later
  generated spawn keeps its own static generated-child instance identity.
- The final same-body `await_all` drains generated spawns from both sides of
  the same-domain generated `do` before the nested repeat check can loop.
- Repeated-observation, missing-drain, cross-domain, and unsupported nested
  repeat shapes remain fail-closed.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO`
  Status: `done`
  Goal: `Ship same-domain generated do after prior await_any followed by generated spawn and same-body drain.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`
  Status: `done`
  Goal: `Implement and document the when/switch same-domain generated-do prior-await_any then spawn analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, prior await_any observation, generated do done-handoff ordering, parameter override, optional binding handoff, and same-domain metadata preservation, later generated spawn scheduling, and mandatory-drain semantics while repeated-observation, missing-drain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; prove -Iperl t/1215-isf-spawn-parameter-binding.t; focused doc audits; focused book/public audits; live-doc audits; broader repeat/child regression; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `done` | Shipped the same-domain generated-do prior-observation spawn-after-do analogue. |

## Decisions

- `2026-05-26`: Select same-domain generated
  `(do child (params ...) [(bind ...)] (domain NAME))` for the prior-
  `await_any` do-then-spawn lifetime proof. Cross-domain behavior, CDC
  semantics, second post-spawn observations, and broader outstanding-child
  lifetime remain outside this slice.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1120-isf-public-live-document-path-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `PASS`; focused behavior `Files=1, Tests=90`; focused doc audits `Files=2, Tests=579`; public/book audits `Files=4, Tests=583`; live-doc audits `Files=4, Tests=608`; repeat/child regression `Files=4, Tests=104`; ISF CI `Files=275, Tests=1888` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` | `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1: ship same-domain prior-awaitany spawn-after-do` | `pending commit hash` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the same-domain
  generated do prior-`await_any` then generated-spawn before same-body
  `await_all` drain analogue.
- `2026-05-26`: Completed the selected leaf; same-domain generated `do` with
  static params, optional generated-top input/output binding handoffs, and
  declared same-domain ownership metadata may now follow a prior multi-pending
  `await_any` and precede a later generated spawn before mandatory same-body
  `await_all` in the documented top-level branch-contained subsets.
