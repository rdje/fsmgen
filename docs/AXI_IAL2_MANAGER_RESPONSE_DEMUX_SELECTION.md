# AXI IAL2 Manager Response Demux Selection

Status: selected next readiness-audit subset; no parser, generator, HDL, or
CLI behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md](AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This selector chooses the next exact IAL2 feature-completeness slice after
bounded AXI auto-ID request-ID drive.

The shipped explicit `auto-id-lifecycle` behavior now allocates request IDs,
drives request-side ID outputs, records selected-ID/busy state, releases IDs
from completion events, and reports generated lifecycle state. It still treats
transaction completion events as authored/environment inputs. That is the next
honesty gap: once FSMGen owns request IDs, it must eventually be able to use
response-channel evidence (`BID`/`RID` plus response handshake events) to
complete the matching logical transaction instead of relying only on abstract
per-transaction completion events.

## Selected Next Subset

The next subset is **AXI manager generated response-demux readiness**.

Proceed with a readiness-audit leaf before generated behavior changes. The
audit should decide whether response demux can be added under the existing
`manager-capacity-status` object and current
`IAL2 -> IAL1/.isf -> IAL0/.fsm -> SystemVerilog` path, or whether a narrower
IAL1/IAL0/SystemVerilog prerequisite is required first.

## Why Response Demux Next

Response demux is the smallest next behavior that directly depends on the
`.23` request-ID lifecycle:

- request IDs are now generated and stored per auto-ID transaction;
- response ID signals remain declared in ID-family metadata but are not used
  for auto-ID completion behavior yet;
- completion release currently trusts per-transaction completion events;
- generated `BID`/`RID` matching is needed before FSMGen can honestly claim
  response matching, ID release from real AXI response evidence, or read-data
  reassembly.

Same-ID ordering queues and read-data interleaving remain important, but they
need a response ownership model first. Full burst and queued policy work are
larger surfaces and should not jump ahead of this readiness decision.

## Audit Questions

The next leaf should answer:

- what public syntax, if any, names response-channel handshake events for the
  first demux slice;
- whether existing transaction `completion` events should remain external
  inputs, become generated internal signals, or gain a separate generated
  demux signal for opted-in response-demux families;
- how write response demux maps `BID` to one active write transaction;
- how read response demux should be bounded without claiming full read-data
  interleaving or burst assembly;
- whether response ID signals (`BID`/`RID`) become generated IAL1 inputs for
  explicit auto-ID lifecycle families;
- what actor-owned state is needed to prove one active transaction owns the
  matched ID;
- whether current IAL1 guard/action expressions can carry equality checks,
  OR fan-in, release guards, and assertion carriers without a new language
  feature;
- how generated completion/release rules interact with the `.23` completion
  release rules;
- which report keys distinguish generated response-demux behavior from
  concrete-ID assertion checks and auto-ID request-ID lifecycle behavior.

## Candidate Public And Generated Surface

The audit should start from the existing public clauses:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto)))

(auto-id-lifecycle
  (write (pool 0 1)))
```

The readiness audit may select a small opt-in clause such as a bounded
`response-demux` clause, or may select a generated interpretation of existing
ID-family/transaction/lifecycle metadata if that remains unambiguous. It must
not introduce a broader full-manager syntax or profile alias in this slice.

Possible generated artifacts to evaluate:

- generated IAL1 response ID inputs for `BID`/`RID`;
- generated response-valid/accepted event inputs or explicit response-event
  metadata;
- generated per-transaction demux completion signals;
- generated release rules gated by response ID equality and active state;
- generated runtime assertions for unmatched response ID, inactive response,
  and ambiguous same-cycle matches;
- generated `.fsm` review artifacts and SystemVerilog lowering through the
  existing expression/storage/assertion paths.

## Report Contract Expectations

The existing report schema can remain:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The readiness audit should decide whether response demux is reported under a
new additive key such as `response_demux`, or as a generated submode inside
`id_response_rule_engine`. The report must stay machine-readable and separate:

- concrete-ID assertion checks;
- auto-ID request-ID lifecycle state;
- generated response-demux checks/rules;
- ordering, interleaving, burst, queued-policy, alias, and VHDL residue.

## Non-Goals

This selector does not implement:

- generated `BID`/`RID` response demux;
- same-ID ordering queues;
- different-ID read-data interleaving or reassembly;
- burst or last-beat tracking;
- address/data/control payload binding;
- repeated instances of one logical transaction;
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
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`

## Rollback

This selector changes only documentation, task-tree, Knowledge Map, roadmap,
book, and memory surfaces. Rolling it back restores `.24` as pending and does
not require reverting parser, generator, HDL, CLI, sample, or test behavior.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.25`: readiness-audit AXI
manager generated response demux after bounded auto-ID request-ID drive,
before implementing response matching, same-ID ordering, read-data
interleaving/reassembly, burst, queued-policy, alias, full-manager, or VHDL
behavior.
