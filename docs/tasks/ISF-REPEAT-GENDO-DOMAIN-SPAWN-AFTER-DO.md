# ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO: Same-Domain Generated Do Then Spawn Before Drain

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Ship the next generated-do spawn-after-do widening: a repeat directly inside
a top-level `when` body or top-level `switch` branch may run a same-domain
generated blocking `(do child (params ...) [(bind ...)] (domain NAME))` while
generated nested spawns are pending, then start one or more additional
generated nested spawns before the mandatory same-body `(await_all done)`
drain.

## Non-Goals

- Do not allow cross-domain generated `do` before a later generated spawn.
- Do not allow later spawn after local or generated `do` when a multi-pending
  `(await_any done)` observation is active before the drain.
- Do not allow `(await_any done)` after the later generated spawn.
- Do not change top-level repeat-body generated-do rules, deeper branch/loop
  nesting, generated child naming, binding handoff semantics, CDC behavior, or
  broader outstanding-child lifetime policy.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape: initial generated `(spawn ...)`, same-domain generated
  `(do child (params ...) [(bind ...)] (domain NAME))`, later generated
  `(spawn ...)`, and same-body `(await_all done)` before nested repeat
  re-entry.
- The generated do waits for its deterministic generated do instance's fresh
  done handoff before the later generated spawn starts.
- The generated do records the static parameter override, optional
  generated-top input/output binding handoffs, and same-domain ownership
  metadata once for its generated top instance.
- The later generated spawn is added to the outstanding generated-spawn set,
  and same-body `await_all` drains both pre-do and post-do generated spawns
  before the nested repeat check can loop.
- Existing rejection coverage for post-`await_any`, cross-domain, and
  unsupported generated-do spawn-after-do remains intact.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO`
  Status: `done`
  Goal: `Ship same-domain generated do followed by generated spawn before same-body drain.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1`
  Status: `done`
  Goal: `Implement and document the when/switch same-domain generated-do spawn-after-do analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, generated do done ordering, parameter override, optional binding handoff, same-domain metadata preservation, later generated spawn scheduling, and mandatory-drain semantics while post-await_any, cross-domain, and unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215; book/public audits; broader repeat/child regression; ISF CI regression; mdBook build; git diff check`
  Commit: `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1: ship same-domain generated do spawn-before-drain`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1` | `done` | Shipped the branch-contained same-domain generated-do-then-later-spawn analogue and kept post-`await_any`, cross-domain, and deeper-nesting variants fail-closed. |

## Decisions

- `2026-05-26`: Select only declared same-domain metadata on the generated do
  site. Cross-domain activation and post-`await_any` spawn-after-do remain
  outside this leaf.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; book/public audit syntax checks; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass`; focused t/1215 `Files=1, Tests=70`; book/public audits `Files=3, Tests=354`; broader repeat/child regression `Files=4, Tests=84`; ISF CI regression `Files=275, Tests=1795` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1` | `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1: ship same-domain generated do spawn-before-drain` | `pending commit` |

## Changelog

- `2026-05-26`: Created active R14 task tree and selected the same-domain
  generated do spawn-after-do before same-body `await_all` drain analogue.
- `2026-05-26`: Shipped the same-domain generated-do then-spawn before
  same-body `await_all` drain analogue and closed the task tree.
