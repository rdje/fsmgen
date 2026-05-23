# ISF-CONTRACT-ACTOR-PARAM-WINDOWS: Temporal Contract Actor-Parameter Windows

## Metadata

- Tree ID: `ISF-CONTRACT-ACTOR-PARAM-WINDOWS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract `within` windows to use actor-local
scalar parameter defaults when those defaults resolve to positive integer
literals.

## Non-Goals

- Do not support transaction parameters as temporal-contract windows.
- Do not support runtime interface signals, storage signals, or arbitrary
  expressions as temporal-contract windows.
- Do not specialize temporal-contract windows through reusable-library
  use-site parameter overrides.
- Do not change monitor timing, sticky-fail behavior, reset behavior,
  SystemVerilog assertion projection, schedule-report key families, or
  generated HDL behavior beyond resolving one more static source kind before
  existing monitor lowering.
- Do not add dynamic contract bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global `always` implication forms, or
  multiple outstanding obligations.

## Acceptance Criteria

- `(contract c (eventually done within WIN_PARAM))` lowers when `WIN_PARAM`
  names an actor-local scalar parameter default whose resolved value is
  positive.
- The older nested `(eventually done (within WIN_PARAM))` spelling lowers
  through the same accepted source path.
- Parameter-backed contract windows lower exactly like equivalent positive
  literal/static actor-constant windows.
- Non-scalar, zero-valued, unknown, transaction-parameter, runtime, and
  expression-valued windows remain fail-closed with targeted diagnostics.
- Schedule reports continue to expose `within_cycles` as the resolved positive
  integer without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-ACTOR-PARAM-WINDOWS`
  Status: `active`
  Goal: `Ship actor-parameter-backed static temporal-contract windows.`
  Children: `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1`,
  `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2`

- ID: `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1`
  Status: `done`
  Goal: `Select temporal-contract actor-parameter windows.`
  Acceptance: `Create the active task tree, record the static actor-parameter
  source boundary, preserve non-goals, and update roadmap/live docs without
  behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending commit`

- ID: `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2`
  Status: `pending`
  Goal: `Implement and document actor-parameter temporal-contract windows.`
  Acceptance: `Positive actor scalar parameters lower as literal contract
  windows; unsupported window tokens fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2` | `pending` | The source boundary is selected; implementation can reuse the existing static actor-parameter default model from wait counts and latency bounds. |

## Decisions

- `2026-05-22`: Select actor-local scalar parameter defaults only. They are
  compile-time static evidence in the current actor shell, matching the
  shipped actor-parameter wait and latency source model, while use-site
  override specialization and transaction parameters remain deferred.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1` | `this commit: ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1: select contract actor-param windows` | `selects static actor-parameter temporal-contract window support` |
| `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected static actor-parameter
  temporal-contract windows.
