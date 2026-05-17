# Repo-Local Task Tree Workflow

This document defines the repo-local task-tree workflow used by FSMGen.
It is intentionally portable: another project can copy this file, the
`docs/tasks/TEMPLATE.md` template, and the commit-subject rule, then replace
the roadmap lane names and live-doc file names with local equivalents.

For a step-by-step setup guide that can be reused by another project, read
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

## Purpose

Use a task tree when a top-level task is too broad to finish safely as one
signoff-level slice, or when a task is expected to discover subtasks and
sub-subtasks over time.

The goal is not to create a second roadmap. The roadmap states the high-level
workstream direction. A task tree owns the recursive breakdown, current
frontier, acceptance criteria, blockers, decisions, validation, and completion
evidence for one top-level task.

## Mandatory Task-Tree Gate For Code Changes

No code, test, source, generated-artifact, or config change may begin without
task-tree ownership already in place.

Before implementation starts:

- Attach the work to an existing active task-tree leaf, or create the smallest
  honest `docs/tasks/*.md` tree or leaf from
  [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- Record enough acceptance criteria and verification scope that the slice can
  be reviewed and recovered after a crash.
- If the work is too small for a multi-leaf breakdown, create a one-leaf tree
  or attach it to a clearly matching existing leaf before changing code.
- Do not treat proposed backlog text as implementation permission. Activate
  or select the owning leaf first.

Documentation-only workflow repairs may update these docs directly, but any
future behavior-bearing implementation still has to pass this task-tree gate
first.

## Active Task Trees

| Tree | Status | Roadmap lane | Current frontier | File |
| --- | --- | --- | --- | --- |
| `ISF-REPEAT-BODY-CHILD-ACTIVATION` | `active` | `R14` | `ISF-REPEAT-BODY-CHILD-ACTIVATION.55` | [docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md](docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md) |

## Proposed Task Trees

Proposed trees record accepted backlog direction, but they are not
PNT-eligible until explicitly activated or until the roadmap selects that lane.

| Tree | Status | Roadmap lane | Proposed first leaf | File |
| --- | --- | --- | --- | --- |
| `FSMGEN-IR-AUDIT` | `proposed` | `architecture backlog` | `FSMGEN-IR-AUDIT.1` | [docs/tasks/FSMGEN-IR-AUDIT.md](docs/tasks/FSMGEN-IR-AUDIT.md) |

## Completed Task Trees

| Tree | Status | Roadmap lane | Completed frontier | File |
| --- | --- | --- | --- | --- |
| `ISF-REPEAT-SPAWN-PARAMS` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md](docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md) |
| `ISF-SPAWN-IN-REPEAT` | `done` | `R14` | `closed` | [docs/tasks/ISF-SPAWN-IN-REPEAT.md](docs/tasks/ISF-SPAWN-IN-REPEAT.md) |
| `ISF-DYNAMIC-WAIT-PHASE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-SYNC-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md](docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md) |
| `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-STAGE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md) |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md) |
| `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md) |
| `ISF-PARAM-WAIT-COUNTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-PARAM-WAIT-COUNTS.md](docs/tasks/ISF-PARAM-WAIT-COUNTS.md) |
| `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md) |
| `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md) |
| `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md) |
| `ISF-SHIFT-LEFT-EXPLICIT-WIDTH` | `done` | `R14` | `closed` | [docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md](docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md) |
| `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md](docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md) |
| `ISF-RULE-RESOURCE-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md](docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md) |
| `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md](docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md) |
| `ISF-WHEN-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md](docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md) |
| `ISF-SWITCH-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md](docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md) |
| `ISF-PHASE-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md](docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md) |
| `ISF-UART-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-UART-FIXTURE-PROMOTION.md](docs/tasks/ISF-UART-FIXTURE-PROMOTION.md) |
| `ISF-BURST-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md](docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md) |
| `ISF-I2C-FIXTURE-PROMOTION` | `done` | `R14` | `closed` | [docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md](docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md) |
| `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` | `done` | `R14` | `closed` | [docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md](docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md) |
| `ISF-DYNAMIC-DIVISOR-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md](docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md) |
| `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE` | `done` | `R14` | `closed` | [docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md](docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md) |
| `ISF-DYNAMIC-DIVISOR-SAFETY` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md](docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md) |
| `ISF-LOOP-BODY-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md) |
| `ISF-RULE-GUARD-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md](docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md) |
| `ISF-MDBOOK-FEATURE-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md) |
| `ISF-REPEAT-BODY-DOC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md) |
| `ISF-LIVE-BOOK-DOCUMENT-PATHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md](docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md) |
| `ISF-TYPE-AGGREGATE-PARITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md) |
| `ISF-CDC-FIXTURE-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-CDC-FIXTURE-MATRIX.md](docs/tasks/ISF-CDC-FIXTURE-MATRIX.md) |
| `ISF-CLOCK-DOMAINS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CLOCK-DOMAINS.md](docs/tasks/ISF-CLOCK-DOMAINS.md) |
| `ISF-DOWNSTREAM-INTEGRATION-SPEC` | `done` | `R14` | `closed` | [docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md](docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md) |
| `ISF-BACKLOG-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md) |
| `ISF-RESOURCE-BACKLOG-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md) |
| `ISF-FEATURE-BACKLOG-STATUS-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md](docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md) |
| `ISF-GENERATED-NAME-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-GENERATED-NAME-POLICY.md](docs/tasks/ISF-GENERATED-NAME-POLICY.md) |
| `ISF-SCHEDULE-REPORT-SCHEMA-VERSION` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md](docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md) |
| `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md](docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md) |
| `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md](docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md) |
| `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md](docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md) |
| `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md](docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md) |
| `ISF-PARAM-OVERRIDE-CONSTANTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md](docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md) |
| `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md](docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md) |
| `ISF-SPEC-TEST-INDEX-SYNC` | `done` | `R14` | `closed` | [docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md](docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md) |
| `DOWNSTREAM-ISSUE-REPRO-FLOW` | `done` | `R14` | `closed` | [docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md](docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md) |
| `ISF-ACTOR-PHASE-STAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md](docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md) |
| `ISF-ACTOR-PARAM-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTOR-PARAM-REPORTS.md](docs/tasks/ISF-ACTOR-PARAM-REPORTS.md) |
| `ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md) |
| `ISF-TEMPORAL-CONTRACT-ASSERTIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md) |
| `ISF-DYNAMIC-WAIT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md](docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md) |
| `ISF-TRANSACTION-PORT-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md](docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md) |
| `ISF-RULE-TRIGGER-STORAGE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md](docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md) |
| `ISF-ACTIVATION-PARAM-OVERRIDES` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md](docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md) |
| `ISF-PUBLIC-CONTRACT` | `done` | `R14` | `closed` | [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md) |
| `ISF-DYNAMIC-WAIT` | `done` | `R14` | `closed` | [docs/tasks/ISF-DYNAMIC-WAIT.md](docs/tasks/ISF-DYNAMIC-WAIT.md) |
| `ISF-ACTIVATION-BIND-EXPRESSIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md](docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md) |
| `COMPOSITION-WIRING-LISPISH` | `done` | `R11` | `closed` | [docs/tasks/COMPOSITION-WIRING-LISPISH.md](docs/tasks/COMPOSITION-WIRING-LISPISH.md) |
| `ISF-WAIT-ZERO` | `done` | `R14` | `closed` | [docs/tasks/ISF-WAIT-ZERO.md](docs/tasks/ISF-WAIT-ZERO.md) |
| `ISF-STORAGE-VAR-SURFACE` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-VAR-SURFACE.md](docs/tasks/ISF-STORAGE-VAR-SURFACE.md) |
| `ISF-STORAGE-VAR-ALIASES` | `done` | `R14` | `closed` | [docs/tasks/ISF-STORAGE-VAR-ALIASES.md](docs/tasks/ISF-STORAGE-VAR-ALIASES.md) |
| `ISF-LIBRARY-SYSTEM-BINDINGS` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md](docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md) |
| `ISF-TRANSACTION-ACTIVATION` | `done` | `R14` | `closed` | [docs/tasks/ISF-TRANSACTION-ACTIVATION.md](docs/tasks/ISF-TRANSACTION-ACTIVATION.md) |
| `ISF-SETTER-SYNTAX` | `done` | `R14` | `closed` | [docs/tasks/ISF-SETTER-SYNTAX.md](docs/tasks/ISF-SETTER-SYNTAX.md) |
| `ISF-CONTROL-FLOW` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONTROL-FLOW.md](docs/tasks/ISF-CONTROL-FLOW.md) |
| `ISF-PORT-BINDING` | `done` | `R14` | `closed` | [docs/tasks/ISF-PORT-BINDING.md](docs/tasks/ISF-PORT-BINDING.md) |
| `ISF-LIBRARIES` | `done` | `R14` | `closed` | [docs/tasks/ISF-LIBRARIES.md](docs/tasks/ISF-LIBRARIES.md) |
| `ISF-SCHEDULE-REPORTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-SCHEDULE-REPORTS.md](docs/tasks/ISF-SCHEDULE-REPORTS.md) |
| `ISF-DATA-WIDTHS` | `done` | `R14` | `closed` | [docs/tasks/ISF-DATA-WIDTHS.md](docs/tasks/ISF-DATA-WIDTHS.md) |
| `ISF-STAGES-CONTRACTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-STAGES-CONTRACTS.md](docs/tasks/ISF-STAGES-CONTRACTS.md) |
| `ISF-RULE-ACTIONS` | `done` | `R14` | `closed` | [docs/tasks/ISF-RULE-ACTIONS.md](docs/tasks/ISF-RULE-ACTIONS.md) |
| `ISF-RESOURCE-CATALOG` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-CATALOG.md](docs/tasks/ISF-RESOURCE-CATALOG.md) |
| `ISF-RESOURCE-PRIORITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-RESOURCE-PRIORITY.md](docs/tasks/ISF-RESOURCE-PRIORITY.md) |
| `ISF-CONFLICTS` | `done` | `R14` | `closed` | [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md) |
| `ISF-COMPOSITION` | `done` | `R14` | `closed` | [docs/tasks/ISF-COMPOSITION-INSTANTIATION.md](docs/tasks/ISF-COMPOSITION-INSTANTIATION.md) |
| `ISF-FIXTURES` | `done` | `R14` | `closed` | [docs/tasks/ISF-FIXTURE-COVERAGE.md](docs/tasks/ISF-FIXTURE-COVERAGE.md) |
| `ISF-COMPATIBILITY` | `done` | `R14` | `closed` | [docs/tasks/ISF-COMPATIBILITY-SURFACE.md](docs/tasks/ISF-COMPATIBILITY-SURFACE.md) |

## R14 ISF Objective Coverage

All currently documented ongoing or unresolved R14 ISF objective families have
task-tree ownership. Already-shipped base objectives such as parsing `.isf`
actors, lowering through `LoweringIR`, emitting scheduled `.fsm`, schedule JSON
emission, and HDL handoff remain recorded in [ROADMAP_STATUS.md](ROADMAP_STATUS.md)
as done work unless a future task reopens them.

| ISF objective family | Owning tree |
| --- | --- |
| Same-cycle output conflicts, fan-in, and fail-closed drive policy | `ISF-CONFLICTS` |
| Generated-child top instantiation, spawn parameter binding, and generated blocking `do` activations | `ISF-COMPOSITION`, `ISF-TRANSACTION-ACTIVATION` |
| Resource arbitration and priority enforcement | `ISF-RESOURCE-PRIORITY` |
| Shareable resource kind catalog and public resource registry | `ISF-RESOURCE-CATALOG` |
| Expression-valued rule assignments and rule action widening | `ISF-RULE-ACTIONS` |
| Transaction stage lowering and temporal contract lowering | `ISF-STAGES-CONTRACTS` |
| Temporal-contract monitor storage schedule-report roles | `ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS` |
| Temporal-contract SystemVerilog assertion projection | `ISF-TEMPORAL-CONTRACT-ASSERTIONS` |
| Actor-level phase/stage schedule-report metadata | `ISF-ACTOR-PHASE-STAGE-REPORTS` |
| Actor-level parameter default schedule-report metadata | `ISF-ACTOR-PARAM-REPORTS` |
| Data-operation width inference for shift/extract/assemble families | `ISF-DATA-WIDTHS` |
| Operation-local `shift_left` width evidence | `ISF-SHIFT-LEFT-EXPLICIT-WIDTH` |
| Single-missing-field `extract` width inference | `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE` |
| Single-missing-part `assemble` width inference | `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` |
| Schedule-report storage classes and schedule JSON stabilization | `ISF-SCHEDULE-REPORTS` |
| Realistic protocol fixtures, strict-mode checks, and end-to-end coverage | `ISF-FIXTURES` |
| Burst-reader realistic fixture promotion | `ISF-BURST-FIXTURE-PROMOTION` |
| UART transmit realistic fixture promotion | `ISF-UART-FIXTURE-PROMOTION` |
| Phase metadata realistic fixture promotion | `ISF-PHASE-FIXTURE-PROMOTION` |
| Switch dispatch realistic fixture promotion | `ISF-SWITCH-FIXTURE-PROMOTION` |
| Conditional `when` realistic fixture promotion | `ISF-WHEN-FIXTURE-PROMOTION` |
| Generated-composition fixture strict/outdir/HDL promotion | `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION` |
| Rule/resource arbitration realistic fixture promotion | `ISF-RULE-RESOURCE-FIXTURE-PROMOTION` |
| Stage/contract realistic fixture promotion | `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION` |
| FIFO controller realistic fixture promotion | `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION` |
| FIFO datapath bank-access realistic fixture promotion | `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION` |
| FIFO reusable-library realistic fixture promotion | `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION` |
| I2C-like realistic fixture promotion | `ISF-I2C-FIXTURE-PROMOTION` |
| Reusable ISF libraries/imports for generic actors and transactions | `ISF-LIBRARIES` |
| Reusable-library clock/reset name remapping inside the single-clock-domain ISF model | `ISF-LIBRARY-SYSTEM-BINDINGS` |
| Multi-clock, asynchronous, and interacting clock-domain semantics | `ISF-CLOCK-DOMAINS` |
| Multi-clock/CDC fixture matrix hardening | `ISF-CDC-FIXTURE-MATRIX` |
| ISF enum/type/aggregate parity with existing `.fsm` semantic machinery | `ISF-TYPE-AGGREGATE-PARITY` |
| Actor-owned scalar storage source vocabulary | `ISF-STORAGE-VAR-SURFACE`, `ISF-STORAGE-VAR-ALIASES` |
| Transaction ports, activation bindings, and actor top-level pin access | `ISF-PORT-BINDING` |
| Expression-valued activation input bindings | `ISF-ACTIVATION-BIND-EXPRESSIONS` |
| Remaining repeat-body child activation widening: nested multi-pending `await_any`, `do` while a nested spawn is pending, cross-domain activation, deeper branch/loop nesting, and broader outstanding-child semantics | `ISF-REPEAT-BODY-CHILD-ACTIVATION` |
| Scalar setter syntax shared by rules and transactions | `ISF-SETTER-SYNTAX` |
| Task-like transaction activation semantics and parameter overrides | `ISF-TRANSACTION-ACTIVATION` |
| Remaining rule-trigger and direct-activation parameter overrides | `ISF-ACTIVATION-PARAM-OVERRIDES` |
| Actor constants as activation parameter override values | `ISF-PARAM-OVERRIDE-CONSTANTS` |
| Removed `(assign ...)` diagnostic truth synchronization | `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC` |
| ISF spec focused-test index synchronization | `ISF-SPEC-TEST-INDEX-SYNC` |
| Self-contained downstream ISF integration handoff | `ISF-DOWNSTREAM-INTEGRATION-SPEC` |
| ISF feature-backlog truth synchronization | `ISF-BACKLOG-TRUTH-SYNC` |
| Resource arbitration and storage-role backlog truth synchronization | `ISF-RESOURCE-BACKLOG-TRUTH-SYNC` |
| ISF feature-backlog status-label truth synchronization after closed task trees | `ISF-FEATURE-BACKLOG-STATUS-SYNC` |
| Generated-name stability policy for schedule reports and generated artifacts | `ISF-GENERATED-NAME-POLICY` |
| Schedule-report schema version metadata | `ISF-SCHEDULE-REPORT-SCHEMA-VERSION` |
| Schedule-report additive/deprecation evolution policy | `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY` |
| Schedule-report assignment provenance and multi-file child summary boundary | `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY` |
| Schedule-report golden fixture matrix | `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX` |
| Schedule-report full-schema stability flag | `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE` |
| Legacy handshake metadata and removed transaction `assign` compatibility | `ISF-COMPATIBILITY` |
| Transaction-local unconditional waits and dynamic loops | `ISF-CONTROL-FLOW`, `ISF-WAIT-ZERO` |
| Non-literal transaction wait counts | `ISF-DYNAMIC-WAIT` |
| Parameter-backed static transaction wait counts | `ISF-PARAM-WAIT-COUNTS` |
| Consecutive runtime wait pending-sample zero-link carrying | `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE` |
| Stage zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-STAGE-SAMPLE` |
| Contract arm zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE` |
| Loop decision zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE` |
| Completion zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE` |
| Independent setter zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE` |
| Independent shift zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE` |
| Independent assemble zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE` |
| Independent extract zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE` |
| Independent bank-load zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE` |
| Independent bank-store zero-bypass for pending-sample runtime waits | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE` |
| Dynamic divisor safety for runtime expression surfaces | `ISF-DYNAMIC-DIVISOR-SAFETY` |
| Actor-constant zero divisor safety for runtime expression surfaces | `ISF-DYNAMIC-DIVISOR-CONSTANTS` |
| Runtime dynamic-wait counter storage schedule-report roles | `ISF-DYNAMIC-WAIT-STORAGE-REPORTS` |
| Generated activation handoff storage schedule-report roles | `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS` |
| Generated activation start/done handoff storage schedule-report roles | `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS` |
| Transaction-local port storage schedule-report roles | `ISF-TRANSACTION-PORT-STORAGE-REPORTS` |
| Rule-trigger source and payload-source storage schedule-report roles | `ISF-RULE-TRIGGER-STORAGE-REPORTS` |
| ISF spec, mdBook, public interface contract, and manifest synchronization | `ISF-PUBLIC-CONTRACT` |
| Public ISF live-document manifest discovery for mdBook chapters | `ISF-LIVE-BOOK-DOCUMENT-PATHS` |
| Repeat-body shipped-subset documentation truth synchronization | `ISF-REPEAT-BODY-DOC-TRUTH-SYNC` |
| Book-facing ISF shipped feature matrix | `ISF-MDBOOK-FEATURE-MATRIX` |
| Standalone enum/aggregate rule-guard backlog truth synchronization | `ISF-RULE-GUARD-DOC-TRUTH-SYNC` |
| Loop-body shipped-clause documentation truth synchronization | `ISF-LOOP-BODY-DOC-TRUTH-SYNC` |
| ISF shipped feature matrix coverage synchronization | `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC` |
| Transaction port/binding feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC` |
| Schedule-report metadata feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC` |
| Downstream issue-bundle feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC` |
| `.isf` CLI example feature matrix coverage | `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC` |

## ISF Task-Tree Rule

All ISF work under `R14` is task-tree-managed by default.

Before implementing any ISF task, slice, or PNT-selected activity, apply the
mandatory task-tree gate above and then:

- Attach it to an existing active ISF task tree, or create a new
  `docs/tasks/*.md` tree from [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- Slice the work into executable leaf nodes before changing scheduler,
  parser, emitter, contract, fixture, or book content.
- Put only executable leaf nodes in the tree's current frontier.
- Implement one frontier leaf at a time.
- For every ISF feature leaf, inspect the reusable synchronization checklist in
  [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
  and record the selected public sync scope in the owning task file, live
  recovery docs, or commit body.
- For every downstream-visible ISF behavior, syntax, diagnostics, report,
  public-facade, generated-artifact, fixture, or deferral change, keep
  [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  synchronized in the same slice. This handoff document is part of the public
  sync set, not optional secondary documentation.
- Update the owning task file when the leaf status, blocker, decision,
  validation evidence, or completion evidence changes.
- Run the full [COMMIT.md](COMMIT.md) workflow after each completed leaf before
  selecting another ISF leaf.

Small ISF documentation-only or diagnostics-only changes still need a tree
entry. If the change is genuinely small, the tree can contain one leaf, but the
task must still be visible in the task-tree ledger before implementation.

## Directory Layout

```text
docs/TASK_TREE.md
docs/tasks/
  TEMPLATE.md
  <TREE>.md
```

`docs/TASK_TREE.md` is the workflow and active-tree index.
Each top-level task owns one file in `docs/tasks/`.
`docs/tasks/TEMPLATE.md` is copied when creating a new top-level tree.

## Definitions

- Task tree: the recursive decomposition of one top-level task.
- Node: one item in that tree.
- Container node: a node with children. It is not directly executable.
- Leaf node: a node with no children. It is the only unit PNT may implement.
- Current frontier: the ordered set of leaf nodes that are eligible to be
  picked next.
- Slice: one completed leaf task plus its tests, docs, live-doc updates, and
  commit workflow.
- Evidence: the validation output, changed-doc summary, and git commit subject
  that prove a leaf was completed.

## ID Rules

Each task tree has a stable top-level ID.

```text
<TREE>
<TREE>.1
<TREE>.1.1
<TREE>.1.1.1
```

Rules:

- `<TREE>` uses uppercase letters, digits, and hyphens.
- Child IDs append dot-separated positive integers.
- IDs are permanent once published.
- Never renumber closed nodes.
- If a new ordering is needed, add new IDs and mark old nodes `superseded` or
  `deferred` with a reason.
- A commit that completes a task-tree leaf must identify the leaf ID in the
  commit subject or in the first body line.

## Status Vocabulary

Use only these statuses.

| Status | Meaning |
| --- | --- |
| `proposed` | Captured but not yet accepted into the active tree. |
| `active` | The top-level tree is open, or a container has unfinished children. |
| `pending` | Ready to be selected once it reaches the current frontier. |
| `in_progress` | Currently being implemented in the worktree. |
| `blocked` | Cannot proceed without a named blocker and unblock condition. |
| `done` | Completed, validated, documented, and committed. |
| `deferred` | Deliberately postponed with an explicit consequence. |
| `superseded` | Replaced by another node, with the replacement ID named. |

## Required Task File Sections

Every top-level task file must contain:

- Metadata: tree ID, status, roadmap lane, created date, last updated date.
- Goal: the user-visible or project-visible outcome.
- Non-goals: what this tree deliberately does not try to solve.
- Acceptance criteria: concrete conditions that close the top-level task.
- Task tree: all known nodes, with status and short result intent.
- Current frontier: ordered leaf nodes that PNT may select next.
- Decisions: accepted technical decisions and their rationale.
- Open questions: unresolved questions that do not block the whole tree yet.
- Blockers: blockers with unblock conditions.
- Verification log: checks run for completed leaves.
- Commit log: leaf IDs mapped to completion commit subjects.
- Changelog: dated edits to the tree itself.

## Node Rules

Every node must be one of these two shapes.

Container node:

```text
- ID: <TREE>.<n>
  Status: active
  Goal: ...
  Children: <TREE>.<n>.1, <TREE>.<n>.2
```

Leaf node:

```text
- ID: <TREE>.<n>
  Status: pending
  Goal: ...
  Acceptance: ...
  Verification: pending
  Commit: pending
```

A node with children must not be marked `done` until every child is `done`,
`deferred`, or `superseded`, and every non-`done` child has a recorded reason.

## Current Frontier Rules

The current frontier is the only list PNT uses when selecting work from a task
tree.

Rules:

- The frontier contains only leaf nodes.
- The frontier is ordered by intended priority.
- A container never appears in the frontier.
- A blocked node stays out of the frontier until unblocked.
- When a leaf is split, remove that leaf from the frontier, mark it `active`,
  add children, and place the first executable child or children in the
  frontier.
- When a leaf completes, remove it from the frontier and add the next eligible
  leaf or leaves.

## PNT Selection Rules

When PNT is asked to continue and at least one active task tree exists:

1. Read `docs/TASK_TREE.md`.
2. Read the active task file named in the `Active Task Trees` table.
3. Pick the first eligible leaf in that file's `Current Frontier`.
4. Implement only that leaf.
5. If the leaf is too broad, split it before implementation and commit the
   tree update as the leaf's honest outcome.
6. Run the required validation for the leaf.
7. Update the task file, live docs, and roadmap if status changed.
8. Run the full commit workflow before selecting another leaf.

If several active trees exist, choose the first active tree in the table unless
the user names another tree or the roadmap status names a different immediate
lane.

## Splitting Rules

Split a node when any of these are true:

- It cannot be completed to signoff quality in one slice.
- It mixes design, implementation, diagnostics, tests, and docs in ways that
  can be reviewed independently.
- It hides an unresolved policy choice behind implementation wording.
- It would require touching unrelated ownership areas in one commit.
- It discovers a lower-level dependency that should be solved first.

Do not split merely to create vague placeholders. Every child must have a
clear goal and a way to verify completion.

## Completion Rules

A leaf is complete only when all of the following are true:

- Implementation or documentation work for that leaf is finished.
- Focused checks passed, and broader checks ran when warranted.
- The owning task file records the result, validation, and commit subject.
- `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`, and `ROADMAP_STATUS.md` are updated when the
  leaf changes project state.
- The commit workflow in `COMMIT.md` has completed.
- `git_message_brief.txt` has been cleared after commit.

Commit hashes are intentionally not required inside the same task-file update:
the final hash cannot be known until after the commit exists. The stable
join key is the leaf ID in the commit subject or first body line. Later status
refreshes may backfill hashes if useful.

## Blocker Rules

A blocked node must record:

- the exact blocker,
- why it blocks the node,
- the unblock condition,
- and the next task that should run instead, if any.

Do not leave a node as `blocked` only because it is large or unclear. Large or
unclear work should be split until a real blocker is visible.

## Relationship To Live Docs

The task tree is the detailed execution ledger.

- `ROADMAP_STATUS.md` remains the canonical high-level workstream status.
- `MEMORY.md` remains the recovery/handoff continuity log.
- `CHANGES.md` remains the chronological technical history.
- `DEVELOPMENT_NOTES.md` remains design rationale.
- `LIVE_ACHIEVEMENT_STATUS.md` remains the latest completed slice summary.
- The mdBook remains user-facing product/language documentation.

Do not duplicate the whole task tree into those files. Link to the task tree
and summarize only the part that changes live project state.

## Copying This Workflow To Another Project

The detailed project-adoption checklist lives in
[docs/TASK_TREE_README.md](docs/TASK_TREE_README.md).

To reuse this approach elsewhere:

1. Copy `docs/TASK_TREE_README.md`.
2. Copy `docs/TASK_TREE.md`.
3. Copy `docs/tasks/TEMPLATE.md`.
4. Add `docs/tasks/` to the project documentation index.
5. Add a commit-workflow rule requiring completed task-tree leaf commits to
   identify the leaf ID.
6. Add the task-tree file to the session bootstrap or fast ramp-up order.
7. Create one top-level task file per broad task.
8. Keep the roadmap high-level and the task files detailed.

The only project-specific parts are roadmap lane names, live-doc filenames,
validation commands, and commit-message conventions.
