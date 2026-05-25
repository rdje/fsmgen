# ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS: Activation Override Contract Window Diagnostics

## Metadata

- Tree ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Fail closed with targeted diagnostics when an activation-site parameter
override would specialize a generated child transaction parameter that is
already used as that child transaction's bounded eventual temporal-contract
`within` window.

## Non-Goals

- Do not implement activation-site override-specialized temporal monitor
  lowering.
- Do not respecialize generated child `.fsm` contract windows per activation
  site, per generated top, per instance, or per trigger edge.
- Do not change accepted generated child or direct transaction parameter
  window defaults when no activation-site override targets the window
  parameter.
- Do not reject activation-site overrides for unrelated generated child
  parameters that are not used by temporal contract windows.
- Do not add source-token fields to schedule reports for contract windows.
- Do not widen transaction parameters into wait counts, repeat counts,
  latency bounds, watchdog limits, data-operation widths, port widths,
  storage widths, or other value domains.
- Do not support runtime interface signals, storage signals, arbitrary
  expressions, dynamic bounds, min/max windows, same-cycle checks, nested
  contracts, expression operands, global `always` implication forms, or
  multiple outstanding obligations.

## Acceptance Criteria

- `spawn`, generated child `do`, and rule `trigger` activation-site parameter
  overrides that target a child transaction parameter used by the target
  transaction's temporal contract window fail closed with a targeted
  diagnostic.
- Overrides of generated child parameters that are not used by temporal
  contract windows continue to follow the existing activation override rules.
- Generated child transaction parameter contract windows without an
  activation-site override continue to lower through the existing resolved
  default path.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`
  Status: `done`
  Goal: `Fail closed when activation-site overrides would imply specialized generated child contract windows.`
  Children: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1`,
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2`

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1`
  Status: `done`
  Goal: `Select activation override temporal-contract window diagnostics.`
  Acceptance: `Create the active task tree, record the fail-closed boundary,
  preserve non-goals, and update roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`
  Commit: `8e08ad4b ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1: select activation override contract-window diagnostics`

- ID: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2`
  Status: `done`
  Goal: `Implement and document targeted diagnostics for activation overrides of contract-window parameters.`
  Acceptance: `Generated child activation overrides of temporal-contract
  window parameters fail closed for spawn, generated do, and rule trigger;
  unrelated overrides remain accepted; generated child defaults without
  overrides remain accepted; specs, book, public contract, downstream
  handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1366-isf-contract-activation-override-windows.t`; focused contract/public/spec/book tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit: ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2: reject contract-window override specialization`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` shipped targeted fail-closed diagnostics for activation overrides of generated child contract-window parameters. |

## Decisions

- `2026-05-25`: Select fail-closed diagnostics, not use-site
  respecialization, for activation-site overrides that target generated child
  transaction parameters used by temporal contract windows. The current
  scheduler lowers one static monitor from the generated child definition, so
  accepting an override without respecialization would be misleading.
- `2026-05-25`: Keep unrelated activation-site overrides accepted. Only
  overrides of parameters that are actually referenced by the target
  transaction's contract window are in this slice.
- `2026-05-25`: Reuse the existing generated activation parameter validation
  gate for this diagnostic. The gate already knows the target child, generated
  instance name, override list, and child transaction parameter declarations,
  so it can reject only the parameter names that the child contract window
  references after the usual unknown-name and shape checks pass.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed`; audits `Files=3, Tests=364` |
| `2026-05-25` | `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` | syntax checks for updated source/tests; focused contract/public/spec/book tests; `./bin/ci-regression isf --no-book`; post-closure public/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed`; focused `Files=13, Tests=452`; broad `Files=272, Tests=1731`; post-closure audits `Files=5, Tests=368` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1` | `8e08ad4b ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1: select activation override contract-window diagnostics` | Selection slice; no behavior change. |
| `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` | `pending this commit: ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2: reject contract-window override specialization` | Implementation slice; closes the tree. |

## Changelog

- `2026-05-25`: Created task tree and selected
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` as the next implementation
  frontier.
- `2026-05-25`: Shipped targeted fail-closed diagnostics for activation-site
  overrides of generated child transaction parameters used by child temporal
  contract windows and closed the task tree.
