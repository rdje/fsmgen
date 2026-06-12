# AXI IAL2 Manager Read Data Payload Contract Selection

Status: selected bounded public contract; no parser, generator, HDL, or CLI
behavior changed by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.44`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md](AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md)
- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md)
- [docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md](AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
- [docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md](AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)

## Purpose

This selector chooses the bounded public `.ppif` contract for the first AXI
read-data payload/status surface after generated read `RID` response demux.
The goal is to make source syntax, report keys, target binding, and residue
movement explicit before parser/report metadata or generated behavior changes.

## Selected Public Syntax

Add one optional `read-data` clause under the existing
`manager-capacity-status` object. The first supported family arm is `read`:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))))
```

`capture-scope single-beat` is mandatory. It means the read-data capture
contract covers one accepted non-burst read response transfer per generated
read demux completion pulse. It does not observe `RLAST`, does not define a
last-beat completion event, and does not assemble multi-beat bursts.

`completion-source response-demux` is mandatory. The data/status validity
strobe for each transaction is the generated read `RID` demux completion
pulse selected by the transaction's `(completion NAME)` field. The raw
top-level `read-complete` event remains the accepted single-beat read response
transfer input; it is not a per-transaction data-valid output by itself.

`data-signal` names the AXI `RDATA` source and carries an explicit positive
bit width. `status-signal` names the AXI `RRESP` source and must have width
`2` in this AXI4 slice. The first contract does not select stricter AXI data
bus width legality beyond requiring a positive integer width.

Each `(transaction NAME ...)` entry binds an existing read auto-ID transaction
to generated payload/status outputs. The output widths are inherited from
`data-signal` and `status-signal`; the first syntax does not accept explicit
per-output widths. The generated completion pulse is the validity strobe for
the updated data/status outputs.

`interleaving single-beat-by-rid` means responses may arrive in any order for
different IDs as independent single-beat transfers matched by `RID`. It is not
multi-beat read-data reassembly and it does not cover interleaved burst beats.

## Static Contract

The first parser/report implementation must enforce:

- `read-data` is optional and may appear at most once under
  `manager-capacity-status`;
- the first supported family subclause is exactly one `(read ...)` arm;
- `(read ...)` requires exactly one `(capture-scope single-beat)`;
- `(read ...)` requires exactly one `(completion-source response-demux)`;
- `(read ...)` requires exactly one `(data-signal NAME (width N))` where `N`
  is a positive integer;
- `(read ...)` requires exactly one `(status-signal NAME (width 2))`;
- `(read ...)` requires exactly one `(interleaving single-beat-by-rid)`;
- at least one `(transaction NAME ...)` entry is required;
- each transaction entry requires one `(data-output NAME)` and one
  `(status-output NAME)`;
- transaction names must match read auto-ID transactions covered by the
  explicit generated read `response-demux` arm;
- generated read response demux is a prerequisite: the source must include a
  read `response-demux` arm with `response-scope single-beat` and
  `transaction-completion generated`;
- positive-width read `id-families`, read `transactions`, and read
  `auto-id-lifecycle` metadata remain required through the response-demux
  prerequisite;
- source names, generated output names, generated storage/rule names, and
  report artifact names must be collision-free;
- `RLAST`, burst length/size metadata, multi-beat capture scopes, explicit
  per-output widths, and interleaving policies other than
  `single-beat-by-rid` are rejected in this first slice.

This selector does not make read-data behavior implicit from read
`response-demux`. The explicit `read-data` clause is required.

## Report Contract

The parser/report metadata slice should keep schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and add a
machine-readable `read_data` key.

For the selected parser/report metadata slice before generated behavior:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_read_demux_completion_pulse
    data_signal: axi0_rdata
    data_direction: generated_input
    data_width: 32
    status_signal: axi0_rresp
    status_direction: generated_input
    status_width: 2
    interleaving_policy: single_beat_by_rid
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_rdata
        status_output: axi0_r0_rresp
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_rdata
        status_output: axi0_r1_rresp
  residue:
    - generated_read_data_capture
    - rlast_completion
    - bursts
    - multi_beat_read_data_reassembly
```

The parser/report slice must leave generated `.isf`, generated `.fsm`, HDL,
and existing `response_demux` behavior unchanged. Because generated data
capture is not shipped in that slice, existing `response_demux.residue` and
`same_id_ordering.residue` should remain honest until a behavior owner moves
covered residue.

After a later behavior owner ships generated single-beat data/status capture,
that owner may set `read_data.generated_behavior: true`, report generated
input/output/rule artifacts, and remove covered single-beat
`read_data_interleaving` residue from the generated read demux subset while
leaving `bursts` and multi-beat reassembly residue.

## Generated Artifact Boundary

The selected next implementation owner is parser/report metadata and static
validation only:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.45
```

That owner should:

- parse and validate the new public `read-data` clause;
- normalize it into structural contract data;
- report `read_data` metadata with `generated_behavior: false`;
- add a runnable `.ppif` sample or extend the read response-demux sample only
  if generated `.isf`, `.fsm`, and HDL behavior remain unchanged;
- update check JSON and normalized semantic JSON support accounting;
- keep shipped generated read `RID` response-demux behavior intact;
- keep mdBook, roadmap, task tree, Knowledge Map, and memory in the same
  commit.

Generated `RDATA`/`RRESP` input declarations, transaction-bound output
updates, generated data-capture rules, generated HDL reachability, and residue
movement require a later exact behavior owner.

## Future Behavior Boundary

A later behavior owner may use this contract to:

- declare `RDATA` and `RRESP` as generated IAL1 inputs;
- declare per-transaction data/status outputs with inherited widths;
- on each generated read demux completion pulse, capture `RDATA`/`RRESP` into
  the matching transaction outputs;
- keep the generated demux completion pulse as the data-valid strobe;
- report generated data-capture inputs, outputs, rules, and unchanged burst
  residue;
- prove `--verify-hdl` for the public read-data sample.

That future behavior remains single-beat/non-burst only unless a later exact
owner selects `RLAST`, burst assembly, or multi-beat read-data reassembly.

## Diagnostics Expected In The Parser/Report Slice

The selected parser/report implementation should reject:

- duplicate `read-data` clauses;
- missing, duplicate, or unsupported read family arms;
- missing or unsupported `(capture-scope ...)`;
- capture scopes other than `single-beat`;
- missing or unsupported `(completion-source ...)`;
- completion sources other than `response-demux`;
- missing or malformed `(data-signal NAME (width N))`;
- non-positive or non-integer data widths;
- missing or malformed `(status-signal NAME (width 2))`;
- status widths other than `2`;
- missing, duplicate, or unsupported `(interleaving ...)`;
- interleaving policies other than `single-beat-by-rid`;
- no transaction entries;
- duplicate transaction entries;
- transaction names not covered by read response-demux auto transactions;
- missing or duplicate data/status outputs per transaction;
- output names that collide with existing inputs, outputs, storage, generated
  demux completion signals, generated auto-ID state, status outputs, or each
  other;
- any `RLAST`, burst, explicit output width, or multi-beat/reassembly clause in
  this first contract.

## Validation Gates

The parser/report implementation should run at least:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Residue

Still out of scope after this selector until later exact owners:

- parser/report implementation of the selected `read-data` clause;
- generated `RDATA`/`RRESP` capture behavior;
- `RLAST` observation or last-beat completion semantics;
- burst or multi-beat assembly;
- different-ID multi-beat read-data reassembly queues;
- same-ID concrete-ID issue-order queues;
- subordinate read-data reordering-depth modeling;
- chunking, atomics, exclusives, or broader B3 transaction classes;
- queued or blocking submission policy;
- full AXI manager syntax;
- `.pif`, `.ppi`, `.axi`, or other profile aliases;
- direct backend lowering;
- VHDL backend or VHDL rerouting behavior.

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, Memory,
and Knowledge Map state. Rolling it back returns the active frontier to the
post-read-data readiness audit and leaves shipped generated read response-demux
behavior unchanged.
