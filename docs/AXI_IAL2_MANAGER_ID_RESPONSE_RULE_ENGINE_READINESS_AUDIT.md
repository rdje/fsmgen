# AXI IAL2 Manager ID/Response Rule-Engine Readiness Audit

Status: implementation boundary selected; no parser, generator, HDL, or CLI
behavior changed by this note.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md](AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)

## Purpose

This audit maps the selected AXI manager ID/response rule-engine subset to the
current codebase before generated behavior changes.

The shipped manager capacity/status object now has the prerequisites needed to
name logical transactions and observe per-transaction request/completion
events. The next question is whether the first ID/response behavior can be
implemented through the current `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path
without pretending to own full ID allocation or response-channel demuxing.

## Readiness Conclusion

The next implementation can be a narrow additive extension to the existing
`manager-capacity-status` object: **concrete transaction ID assertions**.

No separate IAL1, IAL0, or SystemVerilog prerequisite is required first for
this exact slice.

The implementation should not attempt automatic ID allocation, ID release,
same-ID ordering queues, different-ID interleaving, or generated completion
demultiplexing. Those need additional rule-engine design and, for true
response matching, a later channel-level response-valid/payload ownership
model. The first honest behavior is to verify that authored concrete
transaction IDs match the declared AXI request and response ID signals when
the corresponding transaction request or completion event fires.

## Evidence

Existing shipped surfaces provide the required inputs:

- `id_families` records separate read/write request and response ID signal
  names plus positive widths or zero-width absence.
- `transactions[]` records structural transaction kind, name, tag,
  request/completion event names, and concrete ID policy/value when supplied.
- `transaction_event_dispatch` makes per-transaction request/completion events
  generated IAL1 inputs.
- IAL1 interface ports support explicit widths.
- IAL1 immediate `(assert COND [message])` checks lower to `.fsm` `+assert`
  carriers and SystemVerilog clocked concurrent properties through the existing
  assertion backend.
- IAL1 boolean/equality expressions accept the bounded implication shape needed
  for checks such as:

```text
(assert (=> axi0_w0_complete (== axi0_bid 3)) "axi0 w0 BID matches concrete ID")
```

Temporary probes during this audit verified:

- an AXI-like `(assert (=> b_done (== bid 3)))` with a 4-bit `bid` input lowers
  through `.isf -> .fsm` as a `+assert` carrier;
- an assertion-only transaction lowers without introducing synthetic
  start/done ports;
- the supported `FSMGenFull -> GeneratedModuleInfoBuilder ->
  GeneratedModuleEmitter` path emits the corresponding SystemVerilog assertion
  text.

## Selected Implementation Boundary

Proceed with a concrete-ID assertion slice under the existing public
`manager-capacity-status` object.

For each transaction with concrete `(id (value N))` and a present matching ID
family:

- declare the matching request ID signal as a generated IAL1 input with the
  declared family width;
- declare the matching response ID signal as a generated IAL1 input with the
  declared family width;
- emit a request-side assertion:

```text
(assert (=> TRANSACTION_REQUEST_EVENT (== REQUEST_ID_SIGNAL N))
        "TRANSACTION request ID matches concrete ID")
```

- emit a response-side assertion:

```text
(assert (=> TRANSACTION_COMPLETION_EVENT (== RESPONSE_ID_SIGNAL N))
        "TRANSACTION response ID matches concrete ID")
```

The assertion host can be an assertion-only generated transaction. The probe
showed this adds the `+assert` carrier without adding synthetic start/done
ports.

Auto-ID transactions remain report-only for this slice. They do not get
allocated IDs or generated assertions until a later owner selects an allocator
and in-flight ID state model.

## Generated Artifact Impact

Generated IAL1 impact:

- existing capacity/status rules remain unchanged;
- positive-width ID-family request/response signals used by concrete
  transactions become generated inputs;
- assertion-only transaction content emits immediate assertions;
- no new public source object, profile alias, or direct IAL2-to-IAL0 lowering
  is introduced.

Generated IAL0 impact:

- the scheduled `.fsm` gains `+size` entries for used ID signals and a `+assert`
  carrier for concrete request/response ID checks;
- no capacity/status DT rule matrix changes are required.

SystemVerilog impact:

- used ID signals appear as input ports;
- assertions emit through the existing verification-only SystemVerilog
  assertion path;
- Verilog-family non-SystemVerilog output remains assertion-free according to
  the existing assertion contract.

## Report Contract

Retain the existing report schema string:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

Add report metadata describing the generated concrete-ID assertions. A suitable
additive key is:

```text
id_response_rule_engine:
  mode: concrete_id_assertions
  checks:
    - transaction: r0
      kind: read
      phase: request
      event: axi0_r0_request
      id_signal: axi0_arid
      id_value: 3
      enforcement: runtime_assertion
    - transaction: r0
      kind: read
      phase: response
      event: axi0_r0_complete
      id_signal: axi0_rid
      id_value: 3
      enforcement: runtime_assertion
  residue:
    - auto_id_allocation
    - id_release
    - same_id_ordering
    - response_demux
```

The existing `id_families`, `transactions`, and
`transaction_event_dispatch` metadata stay structural and machine-readable.

## Diagnostics

Most concrete-ID diagnostics already exist:

- concrete IDs require `id_families`;
- the matching family must be present and positive width;
- concrete values must fit the declared width;
- ID-family signal names participate in collision checks.

The implementation should add or preserve fail-closed coverage for:

- malformed generated assertion signal references;
- duplicate generated ID inputs colliding with event, status, storage, or
  transaction symbols;
- unsupported attempts to request auto-ID allocation, ID release, ordering,
  response demux, burst tracking, queued/blocking policy, full manager syntax,
  profile aliases, or VHDL behavior in this slice.

## Explicit Non-Goals

This slice does not implement:

- automatic ID allocation;
- dynamic concrete-ID arbitration while issuing;
- ID release or per-ID busy scoreboards;
- same-ID ordering queues;
- different-ID read-data interleaving/reassembly;
- generated `BID`/`RID` response demultiplexing into completion events;
- burst or last-beat tracking;
- address/data/control payload binding;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- VHDL backend or VHDL rerouting behavior.

## Validation Expectations

The implementation leaf should cover:

- generated IAL1 input declarations for used concrete-ID request/response ID
  signals;
- generated IAL1 assertion text for request and response phases;
- generated `.fsm` `+assert` carrier and `+size` ID signal width entries;
- SystemVerilog assertion emission through the existing assertion backend;
- unchanged capacity/status rule matrix behavior for samples without concrete
  ID assertions;
- report metadata under the additive ID/response rule-engine key;
- focused PPIF/parser/CLI diagnostics;
- check JSON, semantic JSON, support accounting, mdBook, Knowledge Map, memory,
  and task-tree sync.

## Selected Next Leaf

Proceed with `IAL2-FEATURE-COMPLETENESS-FRONTIER.18`: implement the additive
concrete transaction ID assertion slice before any auto-ID allocation,
response demux, ordering, burst, queued-policy, alias, full-manager, or VHDL
behavior changes.
