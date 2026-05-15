# ISF-TRANSACTION-ACTIVATION: Task-Like Transaction Activation

## Metadata

- Tree ID: `ISF-TRANSACTION-ACTIVATION`
- Status: `done`
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
  transactions and blocking `do` child activations support per-instance
  `(params ...)` overrides through generated child specialization; rule
  `trigger` and other activation forms remain backlog until implemented.
- Future implementation leaves define exact source shapes, diagnostics,
  lowering, report metadata, and tests before changing parser/scheduler code.
- The task tree remains synchronized with `docs/TASK_TREE.md`, the mdBook
  feature backlog, roadmap status, and live docs.

## Task Tree

- ID: `ISF-TRANSACTION-ACTIVATION`
  Status: `done`
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
  Status: `done`
  Goal: `Implement blocking do parameter overrides.`
  Acceptance: Blocking `(do child (params ...))` parses, validates, lowers to
  reviewable scheduled `.fsm` plus generated composition-top artifacts, reports
  bounded activation and parameter provenance, rejects malformed overrides, and
  reaches HDL generation.
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`;
  focused ISF composition/report tests; `./bin/ci-regression isf --no-book`;
  `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TRANSACTION-ACTIVATION.3: ship do parameter overrides`

- ID: `ISF-TRANSACTION-ACTIVATION.4`
  Status: `done`
  Goal: `Publish report/docs/test closure for the expanded activation surface.`
  Acceptance: The public contract, mdBook, spec, schedule-report metadata,
  regression tiers, and live docs reflect the shipped activation parameter
  surface without freezing raw lowerer internals.
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-TRANSACTION-ACTIVATION.4: close activation docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All leaves in this task tree are complete; future rule-trigger or direct-activation parameter work must open a new explicit tree or leaf before implementation. |

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
- `2026-05-15`: Blocking `(do child (params ...))` is the first general
  activation-site parameter override beyond spawn. It elaborates a generated
  child activation instance with deterministic name
  `{parent}_{child}_do_{ordinal}`, applies the override in the generated top,
  and keeps the parent waiting on that instance's `done` handoff.
- `2026-05-15`: A plain `(do child)` remains an in-parent blocking call when
  the child transaction is local. If that child transaction is already emitted
  as a generated child because another activation site needs generated
  specialization, the plain `do` also uses a generated child activation
  instance so the scheduled parent never references a skipped local child body.
- `2026-05-15`: Close this tree at the shipped static-specialization surface:
  spawn and blocking `do` support `(params ...)`; rule `trigger`, direct
  activation, symbolic parameter values, and expression-valued parameter
  overrides remain backlog and need a fresh task-tree leaf before code changes.

## Open Questions

- None for this closed tree. Rule-trigger and direct-activation parameter
  overrides are deferred, not forgotten.

## Blockers

- None for the documentation boundary slice.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.1` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.3` | `perl -Iperl -c` for changed ISF modules; `prove t/1204-isf-child-composition-clause-boundary.t t/1215-isf-spawn-parameter-binding.t t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t t/1158-isf-public-report-dt-kind-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-TRANSACTION-ACTIVATION.4` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-ACTIVATION.1` | `ISF-TRANSACTION-ACTIVATION.1: document task-like activation` | Formalized current activation boundary; tree remains active. |
| `ISF-TRANSACTION-ACTIVATION.2` | `ISF-TRANSACTION-ACTIVATION.2: specify activation params` | Specified planned `(params ...)` activation syntax and static specialization semantics. |
| `ISF-TRANSACTION-ACTIVATION.3` | `ISF-TRANSACTION-ACTIVATION.3: ship do parameter overrides` | Shipped blocking `do` parameter overrides through generated child activation instances. |
| `ISF-TRANSACTION-ACTIVATION.4` | `ISF-TRANSACTION-ACTIVATION.4: close activation docs` | Closed the shipped activation-parameter documentation and backlog boundary. |

## Changelog

- `2026-05-15`: Created the task-like transaction activation tree and started
  `ISF-TRANSACTION-ACTIVATION.1`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.1`; active frontier
  advances to `ISF-TRANSACTION-ACTIVATION.2`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.2`; active frontier
  advances to `ISF-TRANSACTION-ACTIVATION.3`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.3`; active frontier
  advances to `ISF-TRANSACTION-ACTIVATION.4`.
- `2026-05-15`: Completed `ISF-TRANSACTION-ACTIVATION.4`; task tree closes.
