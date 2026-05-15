# ISF-TRANSACTION-ACTIVATION: Task-Like Transaction Activation

## Metadata

- Tree ID: `ISF-TRANSACTION-ACTIVATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Make ISF transaction activation feel like hardware task invocation while keeping
the lowering static, reviewable, and cycle-explicit. Transactions may declare
formal ports and, where supported, parameters; activation sites must bind actual
signals or parameter values through explicit source syntax.

## Non-Goals

- Do not model transactions as stack-allocated software or SystemVerilog task
  calls.
- Do not hide generated handoff signals, mux selectors, or generated-top bridge
  wiring from review artifacts.
- Do not ship broad parameter overrides before the source shape, lifetime,
  binding visibility, and conflict semantics are documented.
- Do not widen expression-valued bindings, rule-trigger output bindings, or
  snapshot-vs-live timing in this tree unless a later leaf explicitly owns that
  work.

## Acceptance Criteria

- The book and spec clearly state the shipped task-like boundary: scalar
  transaction ports and explicit activation-site `(bind ...)` actuals are
  shipped for `do`, `spawn`, and rule `trigger` in the documented subset.
- The book and spec clearly state the current parameter boundary: spawned child
  transactions support per-instance `(params ...)` overrides; general
  activation-site parameter overrides for `do`, rule `trigger`, and other
  activation forms remain backlog until implemented.
- Future implementation leaves define exact source shapes, diagnostics,
  lowering, report metadata, and tests before changing parser/scheduler code.
- The task tree remains synchronized with `docs/TASK_TREE.md`, the mdBook
  feature backlog, roadmap status, and live docs.

## Task Tree

- ID: `ISF-TRANSACTION-ACTIVATION`
  Status: `active`
  Goal: `Track task-like transaction activation semantics.`
  Children: `ISF-TRANSACTION-ACTIVATION.1`,
  `ISF-TRANSACTION-ACTIVATION.2`, `ISF-TRANSACTION-ACTIVATION.3`,
  `ISF-TRANSACTION-ACTIVATION.4`

- ID: `ISF-TRANSACTION-ACTIVATION.1`
  Status: `done`
  Goal: `Formalize the current task-like transaction activation boundary.`
  Acceptance: The task tree, mdBook, spec, roadmap, and live docs answer the
  task-like transaction question precisely: ports are formal arguments with
  explicit actual bindings in the shipped subset, while general activation-site
  parameter overrides remain future work beyond spawned-child instances.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TRANSACTION-ACTIVATION.1: document task-like activation`

- ID: `ISF-TRANSACTION-ACTIVATION.2`
  Status: `done`
  Goal: `Specify general activation-site parameter override syntax.`
  Acceptance: The book/spec define whether `do`, rule `trigger`, and other
  activation forms share one `(params (NAME value) ...)` override shape, which
  value domain is supported first, how overrides interact with transaction
  defaults, and how diagnostics name missing, duplicate, unknown, or
  shape-incompatible parameters.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TRANSACTION-ACTIVATION.2: specify activation params`

- ID: `ISF-TRANSACTION-ACTIVATION.3`
  Status: `pending`
  Goal: `Implement the next agreed parameter-override activation site.`
  Acceptance: The selected activation site parses, validates, lowers to
  reviewable `.fsm` or generated composition artifacts, reports bounded
  provenance, rejects malformed overrides, and reaches HDL generation where
  applicable.
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-TRANSACTION-ACTIVATION.4`
  Status: `pending`
  Goal: `Publish report/docs/test closure for the expanded activation surface.`
  Acceptance: The public contract, mdBook, spec, schedule-report metadata,
  regression tiers, and live docs reflect the shipped activation parameter
  surface without freezing raw lowerer internals.
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-ACTIVATION.3` | `pending` | The syntax contract is specified; implementation must choose and ship the next activation site. |

## Decisions

- `2026-05-15`: Use "hardware task" only as an author-facing analogy. The
  implementation remains static hardware with persistent scheduled states,
  handoff signals, mux selectors, and generated-top wiring.
- `2026-05-15`: Treat transaction `(ports ...)` as the shipped formal-argument
  surface and activation-site `(bind ...)` entries as shipped actual bindings
  for the documented scalar subset.
- `2026-05-15`: Keep general activation-site parameter overrides separate from
  port actual bindings. Spawned child transactions already support per-instance
  parameter overrides; `do` and rule `trigger` parameter overrides need their
  own source-shape and lowering slices.
- `2026-05-15`: General activation-site parameter overrides will reuse the
  explicit spawn-style `(params (NAME value) ...)` block. They are static
  specialization values, not runtime payload actuals.
- `2026-05-15`: If one transaction is activated with different parameter values
  at different sites, the future lowerer must specialize distinct logical
  transaction instances or cloned scheduled regions. It must not assign mutable
  runtime parameter signals.

## Open Questions

- Which activation site should receive implementation first:
  blocking `do`, rule `trigger`, or another form?

## Blockers

- None for the documentation boundary slice.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.2` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-ACTIVATION.1` | `ISF-TRANSACTION-ACTIVATION.1: document task-like activation` | Formalized current activation boundary; tree remains active. |
| `ISF-TRANSACTION-ACTIVATION.2` | `ISF-TRANSACTION-ACTIVATION.2: specify activation params` | Specified planned `(params ...)` activation syntax and static specialization semantics. |

## Changelog

- `2026-05-15`: Created the task-like transaction activation tree and started
  `ISF-TRANSACTION-ACTIVATION.1`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.1`; active frontier
  advances to `ISF-TRANSACTION-ACTIVATION.2`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.2`; active frontier
  advances to `ISF-TRANSACTION-ACTIVATION.3`.
