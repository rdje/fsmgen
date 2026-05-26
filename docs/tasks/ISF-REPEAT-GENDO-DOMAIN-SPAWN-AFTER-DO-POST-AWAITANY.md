# ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY: Same-Domain Generated Do Then Spawn Then AwaitAny Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next specialized generated-do repeat widening: a repeat directly
inside a top-level `when` body or top-level `switch` branch may run a
same-domain generated blocking `(do child (params ...) [(bind ...)] (domain
NAME))` while generated nested spawns are pending, then start one or more
additional generated nested spawns, then run a multi-pending `(await_any
done)` observation, and finally drain all generated spawns with a same-body
`(await_all done)` before nested repeat re-entry.

## Non-Goals

- Do not allow cross-domain generated `do` before a later generated spawn or
  before post-spawn `await_any`.
- Do not allow later spawn after a prior active multi-pending `(await_any
  done)` observation.
- Do not allow missing same-body `(await_all done)` after the post-spawn
  multi-pending `(await_any done)`.
- Do not change generated-child naming, generated-top binding metadata, CDC
  behavior, deeper branch/loop nesting, or broader outstanding-child lifetime
  policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: initial generated `(spawn ...)`, same-domain
  generated `(do child (params ...) [(bind ...)] (domain NAME))`, later
  generated `(spawn ...)`, post-spawn multi-pending `(await_any done)`, and
  same-body `(await_all done)` before nested repeat re-entry.
- The generated do waits for its deterministic generated do instance's fresh
  done handoff before the later generated spawn starts.
- The generated do instance preserves its static generated-top parameter
  override, optional generated-top input/output binding handoffs, and
  same-domain ownership metadata.
- The post-spawn `await_any` observes either pre-do or post-do generated spawn
  without clearing the outstanding generated-spawn set.
- The final same-body `await_all` drains both pre-do and post-do generated
  spawns before the nested repeat check can loop.
- Existing rejection coverage for cross-domain, prior-`await_any`,
  missing-drain, and unsupported nested repeat shapes remains intact.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY`
  Status: `done`
  Goal: `Ship same-domain generated do followed by generated spawn, post-spawn await_any, and same-body drain.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch same-domain generated-do do-then-spawn post-await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, generated do done ordering, parameter override, optional binding handoff, same-domain metadata preservation, later generated spawn scheduling, post-spawn await_any observation, and mandatory-drain semantics while cross-domain, prior-await_any, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215; book/public audits; broader repeat/child regression; ISF CI regression; mdBook build; git diff check`
  Commit: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1: ship same-domain generated-do post-spawn awaitany`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `done` | Shipped the same-domain generated-do do-then-spawn post-`await_any` surface while keeping cross-domain and prior-active-`await_any` variants deferred. |

## Decisions

- `2026-05-26`: Select only declared same-domain metadata on the generated do
  site. Cross-domain activation remains outside this leaf.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass`; focused t/1215 `Files=1, Tests=80`; book/public audits `Files=3, Tests=373`; broader repeat/child regression `Files=4, Tests=94`; ISF CI regression `Files=275, Tests=1824` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1: ship same-domain generated-do post-spawn awaitany` | `pending commit` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the same-domain
  generated-do do-then-spawn post-`await_any` before same-body `await_all`
  drain analogue.
- `2026-05-26`: Shipped the same-domain generated-do do-then-spawn
  post-spawn `await_any` before same-body `await_all` drain analogue and
  closed the task tree.
