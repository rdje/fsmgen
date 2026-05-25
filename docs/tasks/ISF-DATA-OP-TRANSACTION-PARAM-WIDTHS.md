# ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS: Transaction Parameter Data-Operation Width Evidence

## Metadata

- Tree ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`
- Status: `active`
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
  Status: `active`
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
  Commit: `pending`

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`
  Status: `active`
  Goal: `Accept generated child same-transaction scalar parameter defaults as
  data-operation width evidence.`
  Acceptance: `Generated child transactions accept positive resolved
  transaction parameters in shift/extract/assemble width options, preserve
  existing explicit-width conflicts, report inferred data-register widths, and
  keep unsupported transaction parameter values fail-closed.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3`
  Status: `pending`
  Goal: `Accept direct same-transaction scalar parameter defaults as
  data-operation width evidence.`
  Acceptance: `Direct transactions with params clauses are accepted only when
  at least one same-transaction data-operation width option references a
  declared parameter, and unrelated direct transaction parameters remain
  fail-closed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `done` | `Selection-only leaf established task-tree ownership before implementation.` |
| 2 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `active` | `Generated child transactions already have a parameter publication path, so this is the smallest implementation step.` |
| 3 | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `pending` | `Direct transaction validation should widen only after the generated-child value-domain behavior is proven.` |

## Decisions

- `2026-05-25`: Split the task into generated-child and direct leaves. The
  value resolver is likely shared, but the validation gate is different:
  generated child params are already legal, while direct transaction params
  need a deliberate same-transaction data-width use check.
- `2026-05-25`: Keep activation-site override specialization out of scope.
  Data-operation widths are resolved from the transaction definition's scalar
  parameter defaults; use-site overrides would require generated-child variant
  or generated-top respecialization work.

## Open Questions

- None blocking. Direct transaction support remains a pending leaf, not an
  assumption in the generated-child leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `pending` | `pending` |
| `2026-05-25` | `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1` | `pending` | `selection complete; commit pending` |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2` | `pending` | `pending` |
| `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` | `pending` | `pending` |

## Changelog

- `2026-05-25`: Created task tree, completed the documentation-only ownership
  leaf, and moved the current implementation frontier to
  `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`.
