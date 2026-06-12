# AXI IAL2 Manager ID/Response Rule-Engine Selection

Status: selected next subset; no parser, generator, HDL, or CLI behavior
changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This selector chooses the next exact IAL2 feature-completeness slice after the
shipped AXI manager transaction event dispatch and direction fan-in slice.

The shipped capacity/status object can now identify per-transaction request
and completion events, count read/write occupancy, preserve structural
transaction metadata, and report ID-family metadata. It still does not allocate
IDs, validate dynamic concrete-ID use while issuing, release IDs, keep per-ID
scoreboards, preserve same-ID response order, match `BID`/`RID` responses to
logical transactions, or assemble interleaved read data.

## Selected Next Subset

The next subset is **AXI manager ID/response rule-engine readiness**.

The next leaf should readiness-audit whether the first ID/response rule-engine
slice can build on the existing `manager-capacity-status` object and current
IAL1/IAL0/SystemVerilog substrate, or whether a narrower IAL1/IAL0/SV
prerequisite is required before behavior changes.

The selected audit should stay source-anchored to the existing AXI rule
matrix. It should decide the smallest honest next implementation boundary from
these candidate responsibilities:

- static and generated validation of automatic versus concrete transaction ID
  policies;
- generated request-side ID assignment or ID-use validation for the bounded
  declared read/write ID families;
- response-side `BID`/`RID` match checks against transaction provenance;
- per-direction or per-ID in-flight state required to release an ID at
  completion;
- report metadata that states which ID/response rules are enforced, asserted,
  assumed, or still residue.

## Why This After Event Dispatch

ID allocation and response matching need transaction provenance. With only
direction-level submit/complete events, generated behavior can count pending
reads and writes but cannot know which logical transaction requested an ID,
which concrete ID it claimed, or which transaction should be completed by a
response.

The shipped dispatch slice closes that prerequisite by carrying distinct
per-transaction request/completion events through generated IAL1, generated
IAL0, SystemVerilog, and report metadata. The next feature-completeness risk is
now the ID/response rule engine itself.

## Expected Readiness Questions

The next leaf should answer:

- whether ID-family request/response signals must become generated IAL1 inputs
  for the first implementation slice;
- whether the current IAL1 rule guard/action expression path is sufficient for
  bounded ID equality checks and ID-fit/status logic;
- whether extra actor-owned scalar storage is enough for the first in-flight
  ID state, or whether per-transaction/per-ID scoreboard support needs a
  narrower prerequisite first;
- whether automatic ID allocation can be honestly implemented in the first
  slice, or whether the first behavior slice should restrict itself to
  concrete-ID validation/matching;
- whether response matching can be emitted as scheduler behavior, generated
  runtime assertions, report-only classification, or a combination;
- how to preserve existing capacity/status, ID-family, transaction-envelope,
  and dispatch samples unchanged unless the new sample explicitly opts into
  the ID/response rule-engine behavior.

## Candidate Public And Generated Surface

The audit should start from the existing public clauses:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))))
```

The selector does not introduce a broader `(axi-manager ...)` object, profile
aliases, or new file suffixes. The audit may select one additive opt-in clause
or one generated-behavior interpretation of existing ID/transaction metadata,
but it must keep the mandatory chain:

```text
IAL2 .ppif -> generated IAL1 .isf -> generated IAL0 .fsm -> SystemVerilog
```

Expected generated artifact questions include:

- generated IAL1 port declarations for positive-width ID-family request and
  response signals;
- generated storage for bounded in-flight ID state or match state, if needed;
- generated guard/action expressions for equality, availability, and release;
- generated `.fsm` reviewability of those expressions and storage updates;
- SystemVerilog lowering through the existing expression/storage paths.

## Report Contract Expectations

The existing schedule/report schema can remain:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The readiness audit should decide whether the next implementation uses an
additive report key such as `id_response_rule_engine`, with enough structure
to distinguish:

- enforced static rules;
- generated scheduler rules;
- generated runtime assertions;
- environment assumptions;
- and unsupported residue.

The report must keep existing `id_families`, `transactions`, and
`transaction_event_dispatch` metadata structural and machine-readable.

## Explicit Non-Goals

This selection does not implement or select:

- full ID allocation algorithms across arbitrary streams;
- same-ID ordering queues;
- different-ID read-data interleaving/reassembly;
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
- `perl/FSM/HDL/FlattenedDT.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- `t/297-capability-manifest.t`
- `t/301-check-json-supported-corpus.t`
- `t/303-normalized-semantic-json-supported-corpus.t`

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.17`: readiness-audit the AXI
manager ID/response rule-engine boundary before any ID allocation, response
matching, ordering, burst, queued-policy, alias, full-manager, or VHDL behavior
changes.
