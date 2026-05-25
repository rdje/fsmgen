# ISF-LATENCY-TRANSACTION-PARAM-BOUNDS: Same-Transaction Parameter Latency Bounds

## Metadata

- Tree ID: `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow transaction `(latency (min PARAM) (max PARAM))` bounds to use
same-transaction scalar parameter defaults when the parameter resolves to a
positive integer literal, matching the shipped actor-parameter and
package-constant latency-bound semantics while keeping transaction parameters
local to lowering.

## Non-Goals

- Do not add cross-transaction parameter references.
- Do not accept zero-valued or aggregate/list transaction parameter defaults
  as latency bounds.
- Do not add expression-valued transaction parameter latency bounds.
- Do not add activation-site override specialization for generated child
  latency counters.
- Do not change actor-constant, actor-parameter, package-constant, or runtime
  latency-bound behavior.

## Acceptance Criteria

- Same-transaction scalar parameter defaults resolving to positive integer
  literals are accepted for `min` and `max` latency bounds.
- Transaction-local latency-bound names shadow actor-level constants and
  params.
- Zero-valued and aggregate/list transaction parameter latency bounds fail
  closed with targeted diagnostics before scheduled `.fsm` emission.
- The existing `min <= max` validation continues to use the resolved integer
  values.
- Public specs, downstream handoff, mdBook, roadmap, task tree, README index,
  and live docs are synchronized.
- Focused tests cover accepted min/max parameters, shadowing, zero rejection,
  aggregate rejection, and existing parameter-surface diagnostics.
- Broader ISF regression runs because the lowering change touches shared
  latency and transaction-parameter plumbing.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS`
  Status: `done`
  Goal: `Ship same-transaction scalar parameter defaults for static latency bounds`
  Children: `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1`

- ID: `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1`
  Status: `done`
  Goal: `Accept same-transaction scalar parameter defaults as latency bounds`
  Acceptance: `Implementation, focused regression coverage, public docs, mdBook, live docs, and commit workflow are complete`
  Verification: `syntax checks; focused latency/parameter/public-audit tests Files=16, Tests=455; ci-regression isf --no-book Files=274, Tests=1747; mdbook build docs/book; git diff --check`
  Commit: `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1: support latency transaction params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1` | `done` | Same-transaction scalar latency-bound params are now shipped. |

## Decisions

- `2026-05-25`: Keep transaction parameter latency bounds static and
  positive-only. The resolved integer drives the existing latency counter,
  guard, and timeout lowering; transaction parameters remain local lowering
  inputs rather than scheduled `.fsm` actor parameters.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1` | syntax checks; focused latency/parameter/public-audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=16, Tests=455`; broad ISF `Files=274, Tests=1747` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1` | `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1: support latency transaction params` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the implementation leaf.
- `2026-05-25`: Implemented and documented same-transaction scalar parameter
  latency bounds; closed the tree.
