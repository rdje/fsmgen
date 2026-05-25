# ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS: Temporal Contract Transaction-Parameter Windows

## Metadata

- Tree ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract `within` windows on generated child
transactions to use that child transaction's scalar parameter defaults when
those defaults resolve to positive integer scalar literals.

## Non-Goals

- Do not support transaction-parameter override specialization of contract
  windows at activation sites.
- Do not support parameter declarations on direct/non-generated transactions.
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

- `(contract c (eventually done within PARAM))` lowers on generated child
  transactions when `PARAM` is a scalar parameter declared on that same child
  transaction and resolves to a positive integer literal.
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
  Status: `done`
  Goal: `Ship generated child same-transaction scalar parameter defaults as temporal-contract windows.`
  Children: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1`,
  `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`

- ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1`
  Status: `done`
  Goal: `Select temporal-contract transaction-parameter windows.`
  Acceptance: `Create the active task tree, record the static
  transaction-parameter window boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `5002dea2 ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1: select contract transaction-param windows`

- ID: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`
  Status: `done`
  Goal: `Implement and document generated child same-transaction scalar parameter defaults in temporal-contract windows.`
  Acceptance: `Positive scalar generated child transaction parameter defaults
  lower as literal contract windows; unsupported direct/non-generated,
  cross-transaction, aggregate/list, zero, expression, runtime, and broader
  contract shapes fail closed; specs, book, public contract, downstream
  handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1364-isf-contract-transaction-param-windows.t`; `perl -Iperl -c t/1224-isf-contract-lowering.t`; `perl -Iperl -c t/1362-isf-contract-package-constant-windows.t`; `prove -Iperl t/1224-isf-contract-lowering.t t/1362-isf-contract-package-constant-windows.t t/1364-isf-contract-transaction-param-windows.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` (`Files=10, Tests=388`); `./bin/ci-regression isf --no-book` (`Files=270, Tests=1726`); post-closure public/spec/book audits (`Files=5, Tests=368`); `mdbook build docs/book`; `git diff --check`
  Commit: `fb2088c4 ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2: support contract transaction-param windows`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` shipped the generated-child same-transaction scalar parameter source boundary. |

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
- `2026-05-25`: Keep this value-domain widening scoped to generated child
  transactions because transaction `(params ...)` clauses are currently a
  generated-child surface. Direct/non-generated transaction parameter
  declarations remain rejected before contract lowering.
- `2026-05-25`: Resolve generated child transaction parameters before actor
  constants and actor parameters for contract windows so transaction-local
  names shadow actor-level static names in the same value-domain slot.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` | syntax checks for updated source/tests; focused contract/public/spec/book tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed`; focused `Files=10, Tests=388`; broad `Files=270, Tests=1726`; post-closure audits `Files=5, Tests=368` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1` | `5002dea2 ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1: select contract transaction-param windows` | Selection slice; no behavior change. |
| `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` | `fb2088c4 ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2: support contract transaction-param windows` | Implementation slice; closes the tree. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` as the next implementation
  frontier.
- `2026-05-25`: Shipped generated child same-transaction scalar parameter
  defaults as bounded eventual temporal-contract window sources and closed
  the task tree.
