# ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS: Transaction Parameter Data-Operation Width Evidence

## Metadata

- Tree ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow same-transaction scalar parameter defaults to act as explicit
data-operation width evidence for the shipped `shift_left`, `shift_right`,
`extract`, and `assemble` width-option surfaces when the default resolves to a
positive integer.

## Non-Goals

- Do not implement runtime-signal, arbitrary-expression, or dynamic
  data-operation widths.
- Do not specialize generated child modules or generated tops per activation
  override.
- Do not accept aggregate/list transaction parameter defaults as scalar width
  evidence.
- Do not change existing width precedence, bit ordering, scheduled `.fsm`
  data-operation shapes, schedule-report key families, or HDL projection
  semantics beyond resolved positive width values.

## Acceptance Criteria

- Generated child same-transaction scalar parameter defaults can drive
  `shift_left`/`shift_right` `(width PARAM)` and
  `extract`/`assemble` `(widths PARAM...)` evidence when the resolved default
  is positive.
- Direct/non-generated transactions may use their own scalar parameters for
  the same data-operation width surface only after the validation gate is
  deliberately widened.
- Transaction-local names resolve before actor constants and actor parameters
  inside this value-domain slot.
- Zero, aggregate/list, forward, self/cyclic, runtime, expression, unknown,
  and cross-transaction parameter uses fail closed with targeted diagnostics
  or stay explicitly documented as deferred.
- Focused tests cover accepted generated-child and direct behavior plus
  rejected boundaries.
- `docs/ISF_SPEC.md`, `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, the mdBook, README index, roadmap,
  task tree, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, and
  `LIVE_ACHIEVEMENT_STATUS.md` stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`
  Status: `done`
  Goal: `Ship bounded transaction-parameter data-operation width evidence.`
  Children: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1`,
  `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`,
  `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3`

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select the bounded transaction-parameter data-operation width tree
  before source/test changes.`
  Acceptance: `The task tree, active frontier, roadmap status, README index,
  mdBook backlog, and live docs identify this tree and the next implementation
  leaf without changing parser, scheduler, generated artifacts, public API, or
  runtime behavior.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build;
  git diff check`
  Commit: `eef37d53 ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1: select transaction parameter width tree`

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`
  Status: `done`
  Goal: `Accept generated child same-transaction scalar parameter defaults as
  data-operation width evidence.`
  Acceptance: `Generated child transactions accept positive resolved
  transaction parameters in shift/extract/assemble width options, preserve
  existing explicit-width conflicts, report inferred data-register widths, and
  keep unsupported transaction parameter values fail-closed.`
  Verification: `syntax checks; focused data-operation/public/spec/book tests;
  broader ISF regression; mdBook build; git diff check`
  Commit: `1bca2264 ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2: accept generated child data width params`

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3`
  Status: `done`
  Goal: `Accept direct same-transaction scalar parameter defaults as
  data-operation width evidence.`
  Acceptance: `Direct transactions with params clauses are accepted only when
  at least one same-transaction data-operation width option references a
  declared parameter, and unrelated direct transaction parameters remain
  fail-closed.`
  Verification: `syntax checks; focused data-operation/public/spec/book tests;
  broader ISF regression; mdBook build; git diff check`
  Commit: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3: accept direct data width params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `done` | `Selection-only leaf established task-tree ownership before implementation.` |
| 2 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `done` | `Generated child transactions now accept same-transaction scalar parameter defaults as data-operation width evidence.` |
| 3 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `done` | `Direct/non-generated transactions now accept same-transaction scalar parameter defaults as data-operation width evidence; the task tree is closed.` |

## Decisions

- `2026-05-25`: Split the task into generated-child and direct leaves. The
  value resolver is likely shared, but the validation gate is different:
  generated child params are already legal, while direct transaction params
  need a deliberate same-transaction data-width use check.
- `2026-05-25`: Keep activation-site override specialization out of scope.
  Data-operation widths are resolved from the transaction definition's scalar
  parameter defaults; use-site overrides would require generated-child variant
  or generated-top respecialization work.
- `2026-05-25`: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` keeps transaction
  parameter data-width evidence generated-child-only. Direct transactions that
  already have legal contract-window parameters still fail closed if they try
  to reuse those parameters as data-operation width evidence before `.3`.
- `2026-05-25`: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` widens direct
  transaction validation only when at least one same-transaction
  data-operation width option references a declared transaction parameter.
  Unrelated direct transaction parameter declarations still fail closed.

## Open Questions

- None. This task tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1367-isf-data-op-transaction-param-widths.t`; `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`; focused data-operation/public/spec/book/boundary test runs totaling `Files=16, Tests=405`; `./bin/ci-regression isf --no-book` with `Files=273, Tests=1734`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1367-isf-data-op-transaction-param-widths.t`; focused data-operation/public/spec/book tests with `Files=13, Tests=447`; `./bin/ci-regression isf --no-book` with `Files=273, Tests=1735`; final status/spec/book audits with `Files=4, Tests=366`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `eef37d53 ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1: select transaction parameter width tree` | `selection committed` |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `1bca2264 ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2: accept generated child data width params` | `implementation committed` |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3: accept direct data width params` | `implementation validated; commit in progress` |

## Changelog

- `2026-05-25`: Created task tree, completed the documentation-only ownership
  leaf, and moved the current implementation frontier to
  `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`.
- `2026-05-25`: Implemented generated-child transaction-parameter
  data-operation width evidence and moved the active frontier to direct
  transaction validation.
- `2026-05-25`: Implemented direct/non-generated transaction-parameter
  data-operation width evidence and closed the task tree.
