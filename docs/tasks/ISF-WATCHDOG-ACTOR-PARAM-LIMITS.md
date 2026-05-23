# ISF-WATCHDOG-ACTOR-PARAM-LIMITS: Watchdog Actor-Parameter Limits

## Metadata

- Tree ID: `ISF-WATCHDOG-ACTOR-PARAM-LIMITS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow watchdog limits to use actor-local scalar parameter defaults anywhere
the shipped positive literal and positive actor-constant watchdog limits are
accepted.

## Non-Goals

- Do not support transaction parameters as watchdog limits.
- Do not support runtime interface signals, storage signals, or arbitrary
  expressions as watchdog limits.
- Do not specialize watchdog limits through reusable-library use-site
  parameter overrides.
- Do not change omitted watchdog defaults, watchdog counter decrement/timeout
  semantics, reset behavior, schedule-report key families, or generated HDL
  behavior beyond resolving one more static source kind before existing
  watchdog lowering.
- Do not add distinct per-await limits in one transaction, cross-domain
  watchdog policy, dynamic watchdog limits, or parameter-specialized
  generated-top watchdog counter sizing.

## Acceptance Criteria

- Actor-level `(watchdog WD_PARAM)` lowers when `WD_PARAM` names an
  actor-local scalar parameter default whose resolved value is positive.
- Await-local `(await ready (watchdog WD_PARAM))` lowers through the same
  watchdog counter path as a literal or actor-constant override when
  `WD_PARAM` names a positive actor-local scalar parameter default.
- Parameter-backed watchdog limits lower exactly like equivalent positive
  literal/static actor-constant watchdog limits.
- Non-scalar, zero-valued, unknown, transaction-parameter, runtime, and
  expression-valued watchdog limits remain fail-closed with targeted
  diagnostics.
- Schedule reports and public parser shells continue to expose watchdog limits
  as resolved integers without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WATCHDOG-ACTOR-PARAM-LIMITS`
  Status: `active`
  Goal: `Ship actor-parameter-backed static watchdog limits.`
  Children: `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1`,
  `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2`

- ID: `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1`
  Status: `done`
  Goal: `Select watchdog actor-parameter limits.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter watchdog limits.`
  Acceptance: `Positive actor scalar parameters lower as literal watchdog
  limits; unsupported watchdog tokens fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2` | `pending` | The source boundary is selected; implementation can reuse the existing static actor-parameter default model from waits, latency bounds, and contract windows. |

## Decisions

- `2026-05-22`: Select actor-local scalar parameter defaults only. They are
  compile-time static evidence in the current actor shell, matching the
  shipped actor-parameter wait, latency-bound, and temporal-contract window
  source model, while use-site override specialization and transaction
  parameters remain deferred.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1` | `this commit: ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1: select watchdog actor-param limits` | `selects static actor-parameter watchdog limit support` |
| `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected static actor-parameter
  watchdog limits.
