# AXI IAL2 Manager Auto-ID Lifecycle Selection

Status: selected next subset; no parser, generator, HDL, or CLI behavior
changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This selector chooses the next exact IAL2 feature-completeness slice after the
shipped concrete transaction ID assertion slice.

The shipped public `manager-capacity-status` object can now:

- declare read/write ID-family widths and request/response ID signal names;
- normalize logical transactions as structural metadata;
- carry per-transaction request/completion events through generated IAL1, IAL0,
  SystemVerilog, and report metadata;
- assert concrete request/response ID equality for authored `(id (value N))`
  transactions.

It still does not allocate IDs for `(id auto)`, drive request-side ID signals,
release IDs on completion, maintain per-ID busy state, preserve same-ID
response order, demultiplex `BID`/`RID` responses into logical completions, or
assemble interleaved read data.

## Selected Next Subset

The next subset is **AXI manager auto-ID lifecycle readiness**.

The next leaf should readiness-audit whether a first auto-ID lifecycle slice
can extend the existing `manager-capacity-status` object and current
IAL1/IAL0/SystemVerilog substrate, or whether a narrower request-ID drive,
storage, or expression prerequisite must ship first.

This is deliberately a readiness audit, not an implementation permission slip.
The next behavior-bearing implementation must not start until the audit
records the exact request-ID ownership, state, report, diagnostics, validation,
and rollback boundary.

## Why This After Concrete ID Assertions

Concrete ID assertions prove that ID-family signals, transaction provenance,
assertion-only transactions, generated `.fsm` `+assert` carriers, and the
SystemVerilog assertion backend can carry bounded ID checks.

Auto-ID transactions are still report-only. To make them behavior-bearing, the
manager must establish an ID lifecycle:

- when an auto-ID transaction request fires, choose or validate an available ID;
- drive or otherwise publish the chosen `AWID` or `ARID` value at the request
  boundary;
- mark the ID as in flight;
- release the ID when the corresponding write or read response completes;
- report or assert when no legal ID is available.

That lifecycle is the prerequisite for later same-ID ordering queues and
generated `BID`/`RID` response demux. Selecting response demux directly would
skip the state that tells the manager which IDs are in flight and which
transaction owns each one.

## Expected Readiness Questions

The next leaf should answer:

- whether request ID family signals (`AWID`/`ARID`) should become generated
  IAL1 outputs for auto-ID transactions, while response ID family signals
  (`BID`/`RID`) remain inputs for assertions/matching;
- whether the current IAL1 storage/update substrate can represent a first
  bounded ID busy/free state without adding arrays or loops to IAL1;
- whether the first implementation should support one auto-ID transaction per
  direction, a bounded set of concrete transaction declarations, or the full
  `0 .. 2**ID_WIDTH-1` ID range;
- whether the first ID chooser is a static deterministic allocator, a
  lowest-free-ID chooser, a report-only planner, or a prerequisite owner for a
  more expressive allocator;
- how completion events release IDs before full response demux exists;
- which diagnostics reject ambiguous mixes of auto-ID and concrete-ID
  transactions sharing request or completion events;
- how to keep concrete-ID assertions, capacity/status rule matrices, and
  transaction dispatch behavior unchanged unless the source opts into auto-ID
  lifecycle behavior.

## Candidate Public And Generated Surface

The audit should start from the existing public syntax:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id auto)))
```

The selector does not introduce a broader `(axi-manager ...)` object, profile
aliases, or new file suffixes. The audit may select one additive opt-in clause,
one generated-behavior interpretation of existing `id auto`, or one lower-layer
prerequisite. It must keep the mandatory chain:

```text
IAL2 .ppif -> generated IAL1 .isf -> generated IAL0 .fsm -> SystemVerilog
```

Expected generated artifact questions include:

- generated IAL1 request ID outputs and response ID inputs with declared
  widths;
- generated storage for ID busy/free or selected-ID state;
- generated guard/action expressions for ID availability, assignment, and
  release;
- generated `.fsm` reviewability of the ID lifecycle state transitions;
- SystemVerilog lowering through existing storage/output/expression paths or
  an explicitly selected prerequisite if the substrate is insufficient.

## Report Contract Expectations

The existing schedule/report schema can remain:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The audit should decide whether to extend `id_response_rule_engine` or add a
separate additive key such as `auto_id_lifecycle`, with enough structure to
distinguish:

- generated request-ID drive behavior;
- generated ID busy/free state;
- generated release rules;
- generated runtime assertions;
- static diagnostics;
- environment assumptions;
- and unsupported residue.

Existing `id_families`, `transactions`, `transaction_event_dispatch`, and
`id_response_rule_engine` metadata must remain structural and machine-readable.

## Explicit Non-Goals

This selection does not implement or select:

- a concrete auto-ID allocation algorithm;
- full per-ID scoreboards;
- same-ID ordering queues;
- different-ID read-data interleaving/reassembly;
- generated `BID`/`RID` response demux into logical transaction completions;
- burst or last-beat tracking;
- address/data/control payload binding;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Validation Expectations

The readiness audit should inspect at least:

- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/Adapter/ISF/Parser.pm`
- `perl/FSM/Scheduler/ISF/LoweringIR.pm`
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`
- `perl/FSM/HDL/FlattenedDT.pm`
- `perl/FSM/Backend/GeneratedModuleEmitter.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- `t/1410-isf-assert-carrier.t`
- `t/1411-isf-assert-emit.t`
- `t/297-capability-manifest.t`
- `t/301-check-json-supported-corpus.t`
- `t/303-normalized-semantic-json-supported-corpus.t`

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.20`: readiness-audit AXI
manager auto-ID lifecycle and request-ID drive before any auto-ID allocation,
ID release, response demux, ordering, burst, queued-policy, alias,
full-manager, or VHDL behavior changes.
