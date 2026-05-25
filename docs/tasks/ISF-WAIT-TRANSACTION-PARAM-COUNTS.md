# ISF-WAIT-TRANSACTION-PARAM-COUNTS: Same-Transaction Parameter Wait Counts

## Metadata

- Tree ID: `ISF-WAIT-TRANSACTION-PARAM-COUNTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow `(wait COUNT)` to use a same-transaction scalar parameter default as a
static wait-count source when the parameter resolves to a non-negative integer
literal, matching the shipped actor-parameter and package-constant wait-count
semantics while keeping transaction parameters local to lowering.

## Non-Goals

- Do not add cross-transaction parameter references.
- Do not accept aggregate/list transaction parameter defaults as wait counts.
- Do not add expression-valued transaction parameter wait counts.
- Do not change runtime dynamic wait-count semantics or pending-sample routing.
- Do not add activation-site override specialization for generated child wait
  counts.
- Do not change actor-constant, actor-parameter, package-constant, or runtime
  signal wait-count behavior.

## Acceptance Criteria

- Same-transaction scalar parameter defaults resolving to non-negative integer
  literals are accepted in top-level and inline wait-body contexts.
- Transaction-local wait-count names shadow actor-level constants and params.
- Zero-valued same-transaction parameter waits keep existing zero-wait
  semantics: no wait state and no `transaction_waits[]` entry.
- Aggregate/list transaction parameter wait counts fail closed with a targeted
  diagnostic before scheduled `.fsm` emission.
- Public specs, downstream handoff, mdBook, roadmap, task tree, README index,
  and live docs are synchronized.
- Focused tests cover accepted positive, accepted zero, shadowing, and
  fail-closed aggregate transaction parameter wait counts.
- Broader ISF regression runs if the lowering change touches shared
  wait/parameter plumbing.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WAIT-TRANSACTION-PARAM-COUNTS`
  Status: `done`
  Goal: `Ship same-transaction scalar parameter defaults for static wait counts`
  Children: `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1`

- ID: `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1`
  Status: `done`
  Goal: `Accept same-transaction scalar parameter defaults as static wait counts`
  Acceptance: `Implementation, focused regression coverage, public docs, mdBook, live docs, and commit workflow are complete`
  Verification: `syntax checks; focused wait/parameter/public-audit tests Files=16, Tests=488; ci-regression isf --no-book Files=274, Tests=1746; mdbook build docs/book; git diff --check`
  Commit: `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1: support wait transaction params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1` | `done` | Same-transaction scalar wait-count params are now shipped. |

## Decisions

- `2026-05-25`: Keep transaction parameter wait counts static. The resolved
  non-negative integer controls emitted wait-state expansion, zero remains a
  no-op, and transaction parameters remain local lowering inputs rather than
  scheduled `.fsm` actor parameters.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1` | syntax checks; focused wait/parameter/public-audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=16, Tests=488`; broad ISF `Files=274, Tests=1746` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1` | `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1: support wait transaction params` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the implementation leaf.
- `2026-05-25`: Implemented and documented same-transaction scalar parameter
  wait counts; closed the tree.
