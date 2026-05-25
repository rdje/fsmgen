# ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS: Direct Transaction Contract Parameter Windows

## Metadata

- Tree ID: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow direct/non-generated transaction bounded eventual temporal-contract
`within` windows to use same-transaction scalar parameter defaults when those
defaults resolve to positive integer scalar literals.

## Non-Goals

- Do not support activation-site parameter override specialization of contract
  windows.
- Do not support transaction parameters from other transactions.
- Do not support non-scalar, aggregate/list, self-referential, forward, or
  cyclic transaction parameter defaults as contract windows.
- Do not widen transaction parameters into wait counts, repeat counts, latency
  bounds, watchdog limits, data-operation widths, port widths, storage widths,
  or other value domains.
- Do not change generated child transaction-parameter behavior already shipped
  by `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`.
- Do not support runtime interface signals, storage signals, arbitrary
  expressions, dynamic bounds, min/max windows, same-cycle checks, nested
  contracts, expression operands, global `always` implication forms, or
  multiple outstanding obligations.
- Do not add a contract-window source-token field to schedule reports.

## Acceptance Criteria

- A direct/non-generated transaction may declare `(params (WINDOW 4))` and use
  `WINDOW` in `(contract c (eventually done within WINDOW))`.
- The older nested `(eventually done (within WINDOW))` spelling lowers through
  the same accepted source path.
- Accepted direct transaction parameters lower exactly like equivalent positive
  literal, actor-constant, actor-local scalar-parameter, qualified
  package-constant, and generated child transaction-parameter temporal-contract
  windows.
- Unsupported parameter/window shapes fail closed with targeted diagnostics:
  zero-valued transaction parameters, non-scalar aggregate/list transaction
  parameters, unknown names, transaction parameters from other transactions,
  runtime signals, arbitrary expressions, and remaining broader contract forms.
- Schedule reports continue to expose `within_cycles` as the resolved positive
  integer without adding a separate source-token field.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS`
  Status: `active`
  Goal: `Ship direct/non-generated same-transaction scalar parameter defaults as temporal-contract windows.`
  Children: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1`,
  `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2`

- ID: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1`
  Status: `done`
  Goal: `Select direct transaction temporal-contract parameter windows.`
  Acceptance: `Create the active task tree, record the direct
  transaction-parameter window boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `pending this commit: ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1: select direct contract transaction-param windows`

- ID: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2`
  Status: `pending`
  Goal: `Implement and document direct/non-generated same-transaction scalar parameter defaults in temporal-contract windows.`
  Acceptance: `Positive scalar direct transaction parameter defaults lower as
  literal contract windows; unsupported cross-transaction, aggregate/list,
  zero, expression, runtime, and broader contract shapes fail closed; specs,
  book, public contract, downstream handoff, and focused tests are
  synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2` | `pending` | `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1` selected the bounded direct transaction scalar parameter source boundary. |

## Decisions

- `2026-05-25`: Select only same-transaction scalar parameter defaults on
  direct/non-generated transactions when the resolved default is a positive
  integer scalar literal. Contract windows remain static timing metadata, so
  accepted parameters should resolve before existing temporal monitor
  lowering.
- `2026-05-25`: Keep schedule reports source-token-free for contract windows.
  `temporal_contracts[].within_cycles` remains the resolved positive integer.
- `2026-05-25`: Keep activation-site specialization deferred. A direct
  transaction parameter window uses the transaction definition's resolved
  default in this slice.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1` | `pending this commit: ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1: select direct contract transaction-param windows` | Selection slice; no behavior change. |
| `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2` | `pending` | Implementation slice. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2` as the next implementation
  frontier.
