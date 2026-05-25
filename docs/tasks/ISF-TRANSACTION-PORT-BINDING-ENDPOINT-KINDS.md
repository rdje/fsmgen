# ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS: Transaction-Port Binding Endpoint-Kind Reports

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Expose the authored transaction-port binding endpoint kind through the bounded
ISF schedule report so downstream consumers can distinguish scalar signals,
numeric/exact-width literals, and expression-valued bindings without parsing
the formatted `actor_expression` string.

## Non-Goals

- Do not change transaction-port syntax or activation binding syntax.
- Do not change binding timing, generated `.fsm` lowering, HDL output, or
  same-cycle conflict behavior.
- Do not add rule-trigger output bindings.
- Do not add explicit snapshot-vs-live source syntax.
- Do not expose raw `LoweringIR` assignment internals.
- Do not bump the schedule-report schema version; this task is limited to an
  additive nested report key and its advertised value family.

## Acceptance Criteria

- Public `transaction_port_bindings[]` report entries include an
  `actor_endpoint_kind` field.
- The field is one of `signal`, `literal`, or `expression`.
- Scalar input bindings and scalar output bindings report `signal`.
- Numeric and exact-width input bindings report `literal`.
- Non-empty list-expression input bindings report `expression`.
- Public contract metadata, capability manifest audits, the ISF spec,
  downstream handoff, mdBook, and live docs describe the added report field.
- Focused in-process and CLI schedule-report tests prove the new field without
  changing generated `.fsm` or HDL behavior.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS`
  Status: `done`
  Goal: `Expose authored transaction-port binding endpoint kind in schedule reports.`
  Children: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1`,
  `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2`

- ID: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1`
  Status: `done`
  Goal: `Select the bounded additive endpoint-kind report field.`
  Acceptance: `Task-tree ownership, acceptance criteria, implementation boundary, active frontier, roadmap status, README index, and live docs identify the endpoint-kind report-field slice before code changes.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1: select endpoint-kind reports`

- ID: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2`
  Status: `done`
  Goal: `Implement and document transaction-port binding endpoint-kind report metadata.`
  Acceptance: `Schedule reports emit actor_endpoint_kind for signal, literal, and expression bindings; public contract metadata and downstream/user docs are synchronized; focused public/report tests pass; broad ISF regression runs when warranted.`
  Verification: `syntax checks; focused public/report/spec/book tests; schedule-report freeze-boundary rerun; broad ISF regression; final live-doc/book audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2: report binding endpoint kinds`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Select `actor_endpoint_kind` as a bounded additive
  `transaction_port_bindings[]` field instead of asking downstream consumers
  to infer source shape from `actor_signal` nullability or parse
  `actor_expression`.
- `2026-05-25`: Keep the value family intentionally small:
  `signal` for scalar actor-side endpoints, `literal` for numeric or
  exact-width input operands, and `expression` for non-empty list-expression
  input operands.
- `2026-05-25`: Do not use this task to change timing semantics. The
  existing same-activation, generated-handoff, completion-gated, and
  rule-trigger payload behavior remains documented by existing transaction
  port binding surfaces.
- `2026-05-25`: Keep
  `schedule_report_transaction_port_binding_actor_endpoint_kind_values` as a
  value family, not a presence key family. The broad ISF gate caught the first
  accidental presence-map publication through
  `t/1227-isf-schedule-report-freeze-boundary.t`, and the final rerun passed.

## Open Questions

- None for the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1243-isf-port-binding-schedule-report.t`; `perl -Iperl -c t/1140-isf-public-schedule-report-metadata-audit.t`; `perl -Iperl -c t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1243-isf-port-binding-schedule-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1227-isf-schedule-report-freeze-boundary.t t/1140-isf-public-schedule-report-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf --no-book`; final live-doc/book audits; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1` | `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1: select endpoint-kind reports` | `selection commit` |
| `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2` | `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2: report binding endpoint kinds` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree and selected the bounded
  `actor_endpoint_kind` schedule-report field. The next frontier is
  implementation and documentation synchronization.
- `2026-05-25`: Completed `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2` and
  closed the tree.
