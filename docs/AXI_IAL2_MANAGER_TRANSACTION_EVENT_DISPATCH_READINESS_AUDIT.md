# AXI IAL2 Manager Transaction Event Dispatch Readiness Audit

Status: implementation boundary selected; no parser, generator, HDL, or CLI
behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This audit maps the selected AXI manager transaction event dispatch and
direction fan-in subset to the current codebase before generated behavior
changes.

The shipped transaction-envelope slice records structural logical transactions,
but it intentionally requires each transaction request/completion binding to
reference the existing direction-level abstract events. This audit decides
whether the next slice can safely relax that restriction so distinct
per-transaction request/completion events feed the existing read/write
capacity/status rule matrices.

## Readiness Conclusion

The next implementation can be an additive extension to the existing
`manager-capacity-status` object and current capacity/status generator. No
separate IAL1, IAL0, or SystemVerilog prerequisite is required first for this
exact dispatch/fan-in slice.

Evidence:

- the public `.ppif` transaction parser already accepts scalar `(request EVENT)`
  and `(completion EVENT)` names for each transaction;
- the current generator normalizer is the narrow restriction point: it rejects
  any transaction event that differs from the direction-level
  `read-submit`/`read-complete`/`write-submit`/`write-complete` event;
- the generated capacity/status rule matrix already uses expression guards such
  as `(& submit complete (== pending N))`;
- the ISF rule guard validator accepts nested list expressions and the lowerer
  preserves them as reviewable `.fsm` guard expressions;
- a temporary probe of the exact proposed guard shape lowered
  `(& (| req0 req1) (! (| done0 done1)) (== pending_q 0))` through
  `.isf -> .fsm -> SystemVerilog`. The `.fsm` retained the fan-in guard and
  SystemVerilog emitted factored wires equivalent to `req0 | req1`,
  `done0 | done1`, and the combined enable.

## Selected Implementation Boundary

The next leaf should keep the public syntax inside the existing optional
`(transactions ...)` clause:

```text
(manager-capacity-status axi0
  (clock clk)
  (reset (rst_n active_low async))
  (read-max-pending 4)
  (write-max-pending 2)
  (submit-policy try)
  (read-submit axi0_read_submit)
  (read-complete axi0_read_complete)
  (write-submit axi0_write_submit)
  (write-complete axi0_write_complete)
  (transactions
    (write w0
      (tag wr0)
      (request axi0_w0_request)
      (completion axi0_w0_complete)
      (id auto))
    (write w1
      (tag wr1)
      (request axi0_w1_request)
      (completion axi0_w1_complete)
      (id auto))
    (read r0
      (tag rd0)
      (request axi0_r0_request)
      (completion axi0_r0_complete)
      (id (value 3))))
  (status
    ...))
```

The in-process contract remains machine-readable structural data:

```perl
transactions => [
    {
        kind             => 'write',
        name             => 'w0',
        tag              => 'wr0',
        request_event    => 'axi0_w0_request',
        completion_event => 'axi0_w0_complete',
        id               => { policy => 'auto' },
    },
    {
        kind             => 'read',
        name             => 'r0',
        tag              => 'rd0',
        request_event    => 'axi0_r0_request',
        completion_event => 'axi0_r0_complete',
        id               => { value => 3 },
    },
]
```

The generator should derive per-direction fan-in groups from the union of
transaction events in each direction:

- read request fan-in: unique `request_event` values from read transactions;
- read completion fan-in: unique `completion_event` values from read
  transactions;
- write request fan-in: unique `request_event` values from write transactions;
- write completion fan-in: unique `completion_event` values from write
  transactions.

If a group has exactly one unique event, emit the scalar event as today. If a
group has more than one unique event, emit an OR fan-in expression such as:

```text
(| axi0_w0_request axi0_w1_request)
```

The existing capacity/status matrix can then keep its current four rule kinds,
but substitute aggregate request/completion expressions in the guards:

```text
(& (| axi0_w0_request axi0_w1_request)
   (! (| axi0_w0_complete axi0_w1_complete))
   (== axi0_pending_writes_q 0))
```

This first dispatch slice should not infer transaction events when
`(transactions ...)` is absent. Existing capacity/status, ID-family, and
metadata-only transaction-envelope samples should keep their generated
`.isf`, `.fsm`, and HDL behavior unchanged.

## Public And Generated Surface Impact

Public `.ppif` syntax:

- no new top-level object;
- no broad `(axi-manager ...)` syntax;
- no alias suffixes;
- no payload, burst, ordering, response, or queue policy clauses;
- distinct per-transaction `request` and `completion` event names become
  accepted only inside `(transactions ...)`.

Generated `.isf` impact for dispatch samples:

- declare every unique per-transaction request/completion event as an input;
- preserve direction-level event inputs for legacy aggregate sources when they
  remain in use by the fan-in set;
- use OR fan-in expressions in generated rule guards only when a direction has
  multiple unique events;
- keep generated review artifacts on the mandatory
  `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` chain.

Generated `.fsm` impact:

- DT/rule guard expressions should show the fan-in expression directly, for
  example `<(& (| axi0_w0_request axi0_w1_request) ...)`;
- one-event groups should reduce to the scalar guard, preserving compatibility
  for existing samples.

SystemVerilog impact:

- extra event input ports appear for new dispatch samples;
- OR fan-in and combined rule enables lower through the existing expression
  path;
- no new backend-specific construct is needed.

## Report Contract

Retain the existing report schema string:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

Reason: transaction event dispatch is an additive behavior/report extension to
the existing capacity/status shell, not a new public object family.

Add report metadata describing the generated fan-in. The exact key should be
additive, for example:

```text
transaction_event_dispatch:
  mode: per_transaction_event_fanin
  directions:
    - direction: write
      request_events:
        - axi0_w0_request
        - axi0_w1_request
      completion_events:
        - axi0_w0_complete
        - axi0_w1_complete
      request_fanin: "(| axi0_w0_request axi0_w1_request)"
      completion_fanin: "(| axi0_w0_complete axi0_w1_complete)"
    - direction: read
      request_events:
        - axi0_r0_request
      completion_events:
        - axi0_r0_complete
      request_fanin: axi0_r0_request
      completion_fanin: axi0_r0_complete
```

The existing `transactions[]` entries remain structural AST/report metadata.
The report must still preserve explicit residue for ID allocation, ordering,
response matching, bursts, queued/blocking policy, profile aliases, full AXI
manager behavior, and VHDL.

## Diagnostics

The implementation should fail closed on:

- transaction request/completion events that are missing or malformed;
- read transactions wired to write-prefixed event fields by direction policy,
  when the source uses direction-specific event groups;
- duplicate transaction names or tags;
- duplicate per-direction request event names when the source appears to be
  claiming per-transaction dispatch;
- duplicate per-direction completion event names when the source appears to be
  claiming per-transaction completion provenance;
- event names that collide with clock, reset, status outputs, generated
  storage names, ID-family signal names, or other declared symbols;
- transaction dispatch without a `(transactions ...)` clause;
- unsupported ID allocation, response matching, ordering, burst, payload,
  queued/blocking, profile alias, broader manager, or VHDL clauses.

The compatibility case where a single transaction for a direction binds to the
existing direction-level event remains valid and should reduce to today's
scalar generated guard.

## Code Owners

`perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`:

- relax transaction event validation from "must equal direction event" to
  "must be an identifier owned by the correct transaction direction";
- include transaction event names in collision checks as declared generated
  inputs when they are distinct from the legacy direction event names;
- compute read/write request/completion fan-in expressions;
- feed those expressions to `_direction_rules`;
- declare the unique event inputs in generated `.isf`;
- add additive report metadata for dispatch/fan-in;
- preserve one-event scalar output for compatibility samples.

`perl/FSM/Adapter/IAL2/PPIF.pm`:

- keep the current `(request EVENT)` and `(completion EVENT)` parse shape;
- route distinct event names to the generator;
- add focused diagnostics only if parser-level structural ambiguity is found.

`perl/FSM/Support/RegressionCorpus.pm` and
`perl/FSM/Support/LanguageSurfaceSection.pm`:

- add a separate supported dispatch `.ppif` sample;
- mention optional transaction-envelope metadata with distinct event dispatch
  where the capacity/status shell supports it.

`t/1437-axi-ial2-manager-capacity-status-generator.t` and
`t/1436-ial2-ppif-parser-cli.t`:

- cover the new fan-in sample, generated `.isf`, generated `.fsm`, SV reach,
  report metadata, source identity, and fail-closed diagnostics.

## Public Sample

Add a new checked-in sample in the implementation leaf:

```text
ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

Support-account it separately, likely:

```text
intent.ppif_axi_manager_capacity_status_transaction_event_dispatch
```

## Validation Gates

Focused implementation gates should include:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`
- `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t`
- `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

The readiness audit itself is docs-only. Its runtime probe wrote only to a
temporary directory and verified the exact OR fan-in guard shape through the
existing IAL1 lowerer, IAL0 parser, and SystemVerilog backend.

## Rollback Boundary

Rollback of this audit is documentation-only: revert this note plus the
task-tree, README, roadmap, mdBook, Knowledge Map, and memory pointer updates.
No parser, generator, test, sample, support-accounting, or HDL behavior is
changed by the audit.

## Explicit Residue

Still out of scope:

- ID allocation algorithms;
- dynamic concrete user-ID validation while issuing;
- ID release and per-ID scoreboards;
- same-ID ordering queues;
- different-ID read-data interleaving;
- `BID`/`RID` response matching;
- burst and last-beat tracking;
- address/data/control payload binding;
- transaction-specific completion routing beyond event provenance;
- queued/blocking policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.15`: implement the additive
AXI manager transaction event dispatch and direction fan-in slice.
