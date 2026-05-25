# ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY: Same-Domain Generated Do Before Post-Do Await Any

## Metadata

- Tree ID: `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Ship the next bounded repeat-body child-activation widening: a repeat directly
inside a top-level `when` body or `switch` branch may run a static-parameter
generated blocking `do` with declared same-domain metadata while generated
nested spawns are pending, then use post-do multi-pending `(await_any done)` as
an observation point before a mandatory same-body `(await_all done)` drain.

## Non-Goals

- Do not add cross-domain activation or CDC behavior.
- Do not allow post-do `await_any` without a later same-body `await_all` drain.
- Do not widen single-pending post-do `await_any`, top-level repeat-only
  generated-do domain behavior, new spawn after the do before the drain,
  deeper branch/loop nesting, or broader outstanding-child lifetime semantics.
- Do not change generated child naming, parameter binding, binding handoff,
  or schedule-report key families outside the selected same-domain metadata
  analogue.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `when`-contained and `switch`-contained nested repeat bodies accept the
  selected source shape:
  `(spawn ...)`, `(spawn ...)`, `(do child (params ...) [(bind ...)] (domain NAME))`,
  post-do `(await_any done)`, and later same-body `(await_all done)`.
- The generated do site records same-domain ownership metadata for the
  deterministic generated do instance while preserving static parameter
  binding and optional input/output binding handoffs.
- The post-do `await_any` remains an observation point only; it must not clear
  the pending generated-spawn done set, and the later `await_all` must still
  drain every outstanding generated nested spawn before the nested repeat
  check can loop.
- Existing rejection coverage for missing drains, single-pending post-do
  `await_any`, new spawn after the generated do, cross-domain activation, and
  unsupported nested repeat shapes remains intact.
- ISF spec, downstream handoff, public contract, mdBook, task tree, README
  index, roadmap, live docs, and tests are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY`
  Status: `done`
  Goal: `Ship same-domain generated do before post-do multi-pending await_any.`
  Children: `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1`

- ID: `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1`
  Status: `done`
  Goal: `Implement and document the when/switch same-domain generated-do post-do await_any analogue.`
  Acceptance: `Focused when/switch coverage proves accepted lowering, metadata, generated artifacts, and mandatory-drain semantics while unsupported forms remain fail-closed.`
  Verification: `syntax checks; focused t/1215 and book/public audits; broader repeat/child regression; ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1: ship domain do post-await_any`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1` shipped the branch-contained same-domain generated-do post-do await_any analogue. |

## Decisions

- `2026-05-25`: Select only the branch-contained same-domain metadata analogue
  for generated `do` before post-do multi-pending `await_any`. This mirrors
  the shipped static-parameter and bound generated-do post-do await_any
  behavior while keeping cross-domain activation and new spawn-after-do
  behavior deferred.

## Open Questions

- None blocking this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1215-isf-spawn-parameter-binding.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1215-isf-spawn-parameter-binding.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1202-isf-repeat-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1` | `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1: ship domain do post-await_any` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created active R14 task tree and selected the same-domain
  generated-do post-do multi-pending `await_any` analogue.
- `2026-05-25`: Shipped the when/switch same-domain generated-do post-do
  multi-pending `await_any` analogue with focused tests, user-facing docs,
  live docs, and broader ISF regression coverage.
