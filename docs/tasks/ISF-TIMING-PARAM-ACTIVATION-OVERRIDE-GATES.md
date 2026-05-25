# ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES: Static Timing Parameter Override Gates

## Metadata

- Tree ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Fail closed when generated-child activation-site parameter overrides would
change a child transaction parameter that is consumed by static timing lowering
for repeat counts, wait counts, latency bounds, or top-level await-local
watchdog limits.

## Non-Goals

- Do not implement per-activation generated child respecialization.
- Do not change direct/non-generated transaction parameter semantics.
- Do not add cross-transaction parameter references.
- Do not widen nested control-flow watchdog parameter support.
- Do not change data-operation or transaction-port width override policy in
  this timing-focused slice.
- Do not change generated-top parameter reporting except for preserving already
  accepted same-value override publication.

## Acceptance Criteria

- Generated child `spawn`, generated blocking `do`, and generated rule
  `trigger` activation overrides that target a child transaction parameter used
  by repeat, wait, latency, or top-level await-local watchdog lowering fail
  closed when the override resolves to a different scalar value than the child
  declaration default.
- Same-value overrides for those static timing parameters remain accepted and
  keep using the child definition's default-resolved scheduled `.fsm` timing.
- Unknown parameter, duplicate override, and shape-mismatch diagnostics keep
  their existing precedence.
- Unrelated activation overrides remain accepted.
- Public docs, downstream handoff, mdBook, roadmap, task tree, README index,
  and live docs are synchronized.
- Focused tests cover mismatched and same-value overrides for wait, latency,
  repeat, and top-level await-local watchdog parameter consumers across the
  generated activation forms that share the validation path.
- Broader ISF regression runs because the lowerer change guards generated
  activation validation.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES`
  Status: `done`
  Goal: `Ship fail-closed generated-child static timing parameter override gates.`
  Children: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1`

- ID: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1`
  Status: `done`
  Goal: `Reject mismatched generated-child activation overrides for static timing parameters.`
  Acceptance: `Implementation, focused regression coverage, public docs, mdBook, live docs, and commit workflow are complete.`
  Verification: `syntax checks; focused timing/activation/public-audit tests Files=15, Tests=450; ci-regression isf --no-book Files=275, Tests=1751; mdbook build docs/book; git diff --check`
  Commit: `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1: gate static timing overrides`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1` shipped generated child static timing override gates. |

## Decisions

- `2026-05-25`: Treat static timing transaction parameter overrides like the
  already shipped contract-window boundary: same-value overrides are safe
  because the child scheduled `.fsm` remains default-resolved, while mismatches
  require per-activation specialization and must fail closed.
- `2026-05-25`: Keep the first gate limited to timing consumers that already
  resolve child transaction parameters to concrete lowering-time integers:
  repeat counts, wait counts, latency bounds, and top-level await-local
  watchdog limits.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1` | syntax checks; focused timing/activation/public-audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=15, Tests=450`; broad ISF `Files=275, Tests=1751` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1` | `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1: gate static timing overrides` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the implementation leaf.
- `2026-05-25`: Implemented and documented generated child static timing
  override gates; closed the tree.
