# ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS: Same-Transaction Parameter Await Watchdogs

## Metadata

- Tree ID: `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow top-level await-local `(watchdog PARAM)` overrides to use
same-transaction scalar parameter defaults when the parameter resolves to a
positive integer literal, matching the shipped actor-parameter and
package-constant await-watchdog semantics while keeping transaction
parameters local to lowering.

## Non-Goals

- Do not accept transaction parameters in actor-level `(watchdog PARAM)`.
- Do not add cross-transaction parameter references.
- Do not accept zero-valued or aggregate/list transaction parameter defaults
  as watchdog limits.
- Do not add expression-valued transaction parameter watchdog limits.
- Do not change nested control-flow await watchdog behavior.
- Do not add dynamic watchdog limits or per-await watchdog counter reset
  semantics.
- Do not add activation-site override specialization for generated child
  watchdog counters.
- Do not change actor-literal, actor-constant, actor-parameter,
  package-constant, or runtime watchdog diagnostics outside the await-local
  source set.

## Acceptance Criteria

- Same-transaction scalar parameter defaults resolving to positive integer
  literals are accepted for top-level await-local watchdog overrides.
- Transaction-local watchdog names shadow actor-level static names in the
  top-level await-local watchdog value-domain slot.
- Zero-valued and aggregate/list transaction parameter watchdog limits fail
  closed with targeted diagnostics before scheduled `.fsm` emission.
- Multiple awaits that resolve to the same watchdog parameter value remain
  valid; distinct effective watchdog limits in one transaction still fail
  closed under the existing single-counter policy.
- Public specs, downstream handoff, mdBook, roadmap, task tree, README index,
  and live docs are synchronized.
- Focused tests cover accepted watchdog parameters, shadowing, same-value
  multiple awaits, zero rejection, aggregate rejection, distinct-limit
  rejection, and existing parameter-surface diagnostics.
- Broader ISF regression runs because the lowering change touches shared
  await watchdog and transaction-parameter plumbing.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS`
  Status: `done`
  Goal: `Ship same-transaction scalar parameter defaults for top-level await-local watchdog limits`
  Children: `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1`

- ID: `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1`
  Status: `done`
  Goal: `Accept same-transaction scalar parameter defaults as top-level await-local watchdog limits`
  Acceptance: `Implementation, focused regression coverage, public docs, mdBook, live docs, and commit workflow are complete`
  Verification: `syntax checks; focused watchdog/parameter/public-audit tests Files=16, Tests=459; ci-regression isf --no-book Files=274, Tests=1748; mdbook build docs/book; git diff --check`
  Commit: `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1: support watchdog transaction params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1` | `done` | Same-transaction scalar top-level await-local watchdog params are now shipped. |

## Decisions

- `2026-05-25`: Keep transaction parameter watchdog limits await-local and
  positive-only. Actor-level watchdog metadata remains an actor-shell scalar,
  while await-local transaction parameters resolve inside lowering and are not
  emitted as scheduled `.fsm` actor parameters.
- `2026-05-25`: Preserve the current one-watchdog-counter-per-transaction
  policy. Multiple top-level await-local watchdog declarations may share one
  effective resolved value, but distinct limits still fail closed.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1` | syntax checks; focused watchdog/parameter/public-audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=16, Tests=459`; broad ISF `Files=274, Tests=1748` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1` | `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1: support watchdog transaction params` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the implementation leaf.
- `2026-05-25`: Implemented and documented same-transaction scalar parameter
  top-level await-local watchdog limits; closed the tree.
