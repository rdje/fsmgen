# ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS: Temporal Contract Transaction-Parameter Windows

## Metadata

- Tree ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract `within` windows to use the owning
transaction's scalar parameter defaults when those defaults resolve to positive
integer scalar literals.

## Non-Goals

- Do not support transaction-parameter override specialization of contract
  windows at activation sites.
- Do not support transaction parameters from other transactions.
- Do not support non-scalar, aggregate/list, self-referential, forward, or
  cyclic transaction parameter defaults as contract windows.
- Do not support runtime interface signals, storage signals, arbitrary
  expressions, dynamic bounds, min/max windows, same-cycle checks, nested
  contracts, expression operands, global `always` implication forms, or
  multiple outstanding obligations.
- Do not change monitor timing, sticky-fail behavior, reset behavior,
  SystemVerilog assertion projection, schedule-report key families, or
  generated HDL behavior beyond resolving one more static source kind before
  existing monitor lowering.
- Do not add a contract-window source-token field to schedule reports.

## Acceptance Criteria

- `(contract c (eventually done within PARAM))` lowers when `PARAM` is a
  scalar parameter declared on the same transaction and resolves to a positive
  integer literal.
- The older nested `(eventually done (within PARAM))` spelling lowers through
  the same accepted source path.
- Accepted transaction parameters lower exactly like equivalent positive
  literal, actor-constant, actor-local scalar-parameter, and qualified
  package-constant temporal-contract windows.
- Unsupported parameter sources fail closed with targeted diagnostics:
  zero-valued transaction parameters, non-scalar aggregate/list transaction
  parameters, unknown names, transaction parameters from other transactions,
  runtime signals, arbitrary expressions, and remaining broader contract
  forms.
- Schedule reports continue to expose `within_cycles` as the resolved positive
  integer without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`
  Status: `active`
  Goal: `Ship same-transaction scalar parameter defaults as temporal-contract windows.`
  Children: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1`,
  `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`

- ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1`
  Status: `done`
  Goal: `Select temporal-contract transaction-parameter windows.`
  Acceptance: `Create the active task tree, record the static
  transaction-parameter window boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `pending this commit: ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1: select contract transaction-param windows`

- ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`
  Status: `pending`
  Goal: `Implement and document same-transaction scalar parameter defaults in temporal-contract windows.`
  Acceptance: `Positive scalar transaction parameter defaults lower as literal
  contract windows; unsupported parameter/window shapes fail closed; specs,
  book, public contract, downstream handoff, and focused tests are
  synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` | `pending` | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1` selected the bounded same-transaction scalar parameter source boundary. |

## Decisions

- `2026-05-25`: Select only same-transaction scalar parameter defaults that
  resolve to positive integer scalar literals. Contract windows remain static
  timing metadata in the current scheduler, so accepted parameters should
  resolve before the existing temporal monitor lowering.
- `2026-05-25`: Keep schedule reports source-token-free for contract windows.
  `temporal_contracts[].within_cycles` remains the resolved positive integer.
- `2026-05-25`: Defer activation-site specialization. A transaction
  parameter window uses the transaction definition's resolved default in this
  slice; distinct activation override specialization remains separate generated
  child work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1` | `pending this commit: ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1: select contract transaction-param windows` | Selection slice; no behavior change. |
| `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` | `pending` | Implementation slice. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` as the next implementation
  frontier.
