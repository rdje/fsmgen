# AXI IAL2 Manager Auto-ID Lifecycle Readiness Audit

Status: completed readiness audit; no parser, generator, HDL, CLI, or
support-accounting behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md](AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This audit decides whether the next behavior-bearing IAL2 AXI manager slice can
directly implement automatic ID allocation and request-ID drive for authored
`(id auto)` transactions.

The shipped surface already has the necessary structural pieces to describe the
problem:

- `id_families` declares read/write ID widths and request/response ID signal
  names;
- `transactions` carries logical read/write transactions as machine-readable
  structural metadata;
- `transaction_event_dispatch` binds each transaction to request and completion
  events;
- `id_response_rule_engine` emits concrete-ID request/response assertions for
  authored `(id (value N))` transactions.

The missing feature is the lifecycle for `id auto`: choose a legal request ID,
drive the request-side ID signal, remember which ID is busy, release it at the
matching completion boundary, and report/assert no-ID-available situations.

## Readiness Conclusion

Do not implement a full automatic ID allocator directly in the next slice.

The current IAL1/IAL0/SystemVerilog substrate is good enough for a first
bounded request-ID lifecycle once the public contract is precise:

- generated IAL1 can declare scalar outputs, scalar inputs, scalar storage, and
  assertion-only transactions;
- generated IAL0 `.fsm` can carry reviewable storage updates and `+assert`
  carriers;
- the current SystemVerilog path can lower scalar ports, storage, rules, and
  verification-only assertions.

The public IAL2 contract is not precise enough yet to make every existing
`(id auto)` transaction behavior-bearing. AXI ID widths are allowed in `0..32`;
a positive width does not define a sensible allocation pool by itself. Treating
`width 32` as an implicit pool of every ID value is not reviewable, and
silently serializing all auto-ID traffic to one ID would lose the concurrency
that the AXI manager work is intended to model.

The selected next owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.21`: select the bounded auto-ID pool and
request-ID drive contract before any auto-ID allocation behavior changes.

## Evidence Read

This audit read the shipped generator and parser surfaces, support tests, and
design evidence for:

- capacity/status storage and status-output generation;
- ID-family width and signal validation;
- transaction-envelope structural metadata;
- transaction event dispatch and direction fan-in;
- concrete-ID request/response assertions;
- AXI ID/order evidence and source-to-rule responsibility matrix;
- IAL1 interface direction, storage, rule update, expression, assertion, and
  JSON report substrate;
- generated `.fsm` assertion carriers and SystemVerilog assertion emission;
- mdBook, roadmap, task-tree, and Knowledge Map handoff surfaces.

## Substrate Findings

Request ID signals need a direction split that the current concrete-ID slice
does not yet model. Concrete-ID assertions observe both request and response ID
signals, so the first implementation declared the used ID-family signals as
generated inputs. Auto-ID lifecycle is different: request-side `AWID`/`ARID`
must become generated outputs for the manager-owned ID drive, while
response-side `BID`/`RID` remain inputs until later response matching and demux
work.

The existing storage/update substrate can represent scalar lifecycle state.
That is enough for selected-ID registers, one-bit busy flags, and small
bounded pools. It is not enough to infer a full allocator over every possible
ID value for widths up to 32 without a contract that bounds the pool or chooses
an implementation strategy.

The existing abstract completion events can release IDs for the first lifecycle
slice, but that release remains a transaction-level approximation. Generated
`BID`/`RID` response demux, read-data reassembly, same-ID ordering queues, and
burst/last-beat tracking remain separate future owners.

## Required Contract Before Implementation

The next selector must choose an exact public contract for bounded auto-ID
lifecycle. It may choose either:

- a behavior-bearing interpretation of existing `(id auto)` only when a
  bounded allocation pool is explicitly defined; or
- an additive opt-in clause under `manager-capacity-status`, such as an
  `auto-id-lifecycle` or `auto-id-pool` clause, that defines the legal pool and
  request-ID drive behavior.

Until that contract is selected, existing `(id auto)` transactions remain
structural/report-only metadata.

The selected contract must define:

- whether write and read families have independent pools;
- how pool values are bounded and validated against each family width;
- whether request-ID outputs are registered or combinational at the abstract
  request event boundary;
- what storage is generated for selected IDs and busy/free state;
- how completion events release IDs before full response demux exists;
- what no-ID-available status, diagnostic, assertion, or assumption is emitted;
- how auto-ID and concrete-ID transactions may share request/completion events;
- how the behavior remains backend-language-neutral across the IAL contracts.

## Report Contract Expectations

The next behavior-bearing implementation should add a separate structural
report key named `auto_id_lifecycle`, rather than overloading
`id_response_rule_engine`. The latter currently reports concrete-ID assertion
checks; auto-ID lifecycle is request-ID drive plus state ownership.

The `auto_id_lifecycle` report should be machine-readable and include at least:

- `mode`;
- per-family request-ID output signal and response-ID input signal;
- bounded pool values;
- generated storage names and widths;
- request allocation rules;
- completion release rules;
- generated runtime assertions or environment assumptions;
- no-ID-available behavior;
- diagnostics;
- unsupported residue.

Existing `id_families`, `transactions`, `transaction_event_dispatch`, and
`id_response_rule_engine` report entries must remain additive and compatible.

## Generated Artifact Boundary

The first implementation after the contract selector should be limited to the
`IAL2 .ppif -> generated IAL1 .isf -> generated IAL0 .fsm -> SystemVerilog`
path.

Expected generated artifact changes for that later slice are:

- request-side ID-family signals become generated IAL1 outputs for auto-ID
  families;
- response-side ID-family signals remain generated IAL1 inputs;
- generated storage records selected ID and busy/free state for the bounded
  pool;
- generated rules drive request ID, allocate state on request events, and
  release state on completion events;
- generated assertions or diagnostics guard no-ID-available and ambiguous
  shared-event cases;
- generated `.fsm`, HDL, check JSON, normalized semantic JSON, mdBook, roadmap,
  and Knowledge Map surfaces change in the same task-owned slice.

## Diagnostics Expected Later

The implementation owner should reject at least:

- auto-ID lifecycle on a zero-width family;
- pool values outside the declared family width;
- duplicate pool values;
- an empty pool for a family with auto-ID transactions;
- generated signal/storage names colliding with existing ports, events, or
  status outputs;
- request or completion event sharing that makes the selected ID ownership
  ambiguous;
- mixes of auto-ID and concrete-ID behavior on one event when the selected
  contract cannot prove unique ownership.

## Validation Gates For The Next Selector

The next contract selector should run documentation and handoff gates:

- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

The first behavior-bearing implementation after that selector should also run
focused generator, `.ppif` CLI, check JSON, normalized semantic JSON, and HDL
tests for generated request-ID drive.

## Residue

Still out of scope after this audit:

- full automatic ID allocation implementation;
- ID release implementation;
- same-ID ordering queues;
- different-ID read-data interleaving and reassembly;
- generated `BID`/`RID` response demux;
- burst and last-beat tracking;
- address/data/control payload binding;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Rollback

This slice changes only documentation, task-tree, Knowledge Map, and memory
surfaces. Rolling it back removes the audit and restores `.20` as pending; no
parser, generator, HDL, CLI, sample, or test behavior must be reverted.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.21`: select the bounded AXI
auto-ID pool and request-ID drive contract before any auto-ID allocation,
request-ID output, ID release, response demux, ordering, burst, queued-policy,
alias, full-manager, or VHDL behavior changes.
