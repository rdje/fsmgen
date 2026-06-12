# AXI IAL2 Manager Transaction Event Dispatch Selection

Status: selected next subset; no parser, generator, HDL, or CLI behavior
changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This selector chooses the next exact IAL2 feature-completeness slice after the
shipped static transaction-envelope metadata.

The shipped `(transactions ...)` entries are structural and useful for reports,
but the first slice intentionally requires each transaction to bind to the
existing direction-level abstract submit/complete events. That keeps generated
artifacts unchanged, but it also means generated behavior cannot yet know which
logical transaction caused a request or completion.

## Selected Next Subset

The next subset is **AXI manager transaction event dispatch and direction
fan-in**.

The subset should readiness-audit whether the existing capacity/status shell
can safely accept distinct per-transaction request and completion event
bindings, then aggregate them into the direction-level read/write occupancy
rules.

Candidate public syntax stays within the existing `(transactions ...)` shape:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id (value 3))))
```

The generated review artifacts would remain on the mandatory chain:

```text
IAL2 .ppif -> generated IAL1 .isf -> generated IAL0 .fsm -> SystemVerilog
```

## Why This Before ID Allocation

ID allocation and response matching need stable transaction provenance. With
only direction-level `read-submit`, `read-complete`, `write-submit`, and
`write-complete` events, the generated manager can count outstanding work but
cannot know which logical transaction requested an ID, reused a concrete ID,
or completed.

Per-transaction event dispatch is therefore the narrow prerequisite before
any honest implementation of:

- auto ID allocation;
- dynamic concrete user-ID validation while issuing;
- per-ID busy/block feedback;
- same-ID ordering queues;
- `BID`/`RID` response matching;
- read-data interleaving/reassembly;
- transaction-specific completion reporting.

## Expected Readiness Questions

The next leaf should answer:

- whether the current IAL1 expression/lowering path can express fan-in of
  multiple request events and multiple completion events per direction;
- whether per-transaction event ports should be accepted only when
  `(transactions ...)` is present, or whether direction-level events remain as
  explicit aggregate inputs;
- how to preserve the existing capacity/status sample and ID-family sample
  unchanged;
- what report metadata should identify the generated fan-in groups;
- whether generated `.isf`, generated `.fsm`, and HDL changes can stay limited
  to extra event inputs and OR-like aggregate guards;
- which diagnostics should reject duplicate event bindings, mixed aggregate
  plus per-transaction ambiguity, unsupported per-transaction payloads,
  dispatch that crosses read/write directions, or missing completion events.

## Explicit Non-Goals

This selection does not implement or select:

- ID allocation algorithms;
- dynamic ID release or per-ID scoreboards;
- `BID`/`RID` response matching;
- same-ID ordering queues;
- different-ID read-data interleaving;
- bursts or last-beat tracking;
- address/data/control payload binding;
- queued/blocking policy;
- full AXI manager syntax such as a broader `(axi-manager ...)` object;
- `.axi` or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Validation Expectations

The readiness audit should inspect at least:

- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm`
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm`
- `perl/FSM/HDL/FlattenedDT.pm`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`
- `t/297-capability-manifest.t`
- `t/301-check-json-supported-corpus.t`
- `t/303-normalized-semantic-json-supported-corpus.t`

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.14`: readiness-audit the AXI
manager transaction event dispatch and direction fan-in subset before any
generated behavior changes.
