# AXI IAL2 Manager Read Single-Beat Depth-3 Queue-Head Read-Data Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.152` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.152`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.153`, generated scalar read-data
over read single-beat depth-3 queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, generated artifact, or
HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.149` generated read single-beat depth-3 queue-head response-demux behavior;
- `.151` support-detail expectation alignment;
- `.146` generated read-data over read single-beat multi-group depth-2
  queue-head response-demux;
- `.113` generated one-group depth-2 read single-beat queue-head read-data;
- `.148` deeper queue-head readiness audit;
- current read-data coverage and read-data generation helpers in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- focused generator and PPIF/CLI tests, public PPIF samples, support
  accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map.

## Live Findings

The shipped depth-3 sample remains generated response-demux-only:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif
  generated=1
  boundary=generated_read_single_beat_queue_head_demux
  groups=depth 3: r0/r1/r2
  read_data=absent
```

A temporary `/tmp/fsmgen-depth3-read-data-probe.ppif` was derived from that
sample by adding scalar single-beat `read-data` bindings for `r0`, `r1`, and
`r2`. It fails closed at the current expected diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head single-beat coverage requires one or more depth-2 concrete same-ID read queue groups in this slice
```

## Code Findings

`_read_data_response_demux_transaction_coverage` already recognizes generated
queue-head read single-beat response-demux and maps it to
`generated_queue_head_response_demux_completion_pulse`, but it currently
requires every generated queue-head group to have depth `2` and exactly two
transactions.

After coverage admits transactions, the downstream read-data paths already
iterate transaction bindings:

- generated `RDATA` and `RRESP` source inputs are derived once
  `read_data.generated_behavior` is true;
- scalar data/status outputs are emitted for every covered transaction;
- read-data capture rules are generated from each transaction's generated
  completion pulse;
- report fields, generated artifact lists, `.fsm` lowering, and SystemVerilog
  HDL already handle the existing one-group and multi-group depth-2
  single-beat queue-head read-data samples.

The remaining implementation blocker is therefore the local depth-2 coverage
gate, not a parser, lowerer, report, or HDL substrate gap.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.153`, generated scalar read-data
over read single-beat depth-3 queue-head response-demux.

The `.153` implementation boundary is:

- read family only;
- `response_demux.read.response_scope single-beat`;
- generated queue-head response-demux boundary
  `generated_read_single_beat_queue_head_demux`;
- exactly one duplicate concrete read-ID group with three read transactions at
  computed depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- scalar single-beat `RDATA`/`RRESP` capture bindings for all three
  transactions;
- completion validity
  `generated_queue_head_response_demux_completion_pulse`;
- one support-accounted public PPIF sample; and
- preservation of existing depth-2 queue-head read-data and depth-3
  response-demux-only behavior.

## Deferred Work

The following remain outside `.153` unless separately selected:

- read burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple or mixed depth-3 queue-head groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue boundary refinement;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering; and
- VHDL.

## Validation Gates For .153

The implementation should run:

- focused generator and PPIF/CLI tests for the new support-accounted depth-3
  read-data sample;
- schedule JSON, strict check JSON, strict semantic JSON, generated HDL, and
  `--verify-hdl` probes for the new sample when tools are available;
- preservation probes for the `.149` depth-3 response-demux-only sample and
  the existing depth-2 one-group and multi-group single-beat queue-head
  read-data samples;
- mdBook, README, roadmap, task tree, Memory, Knowledge Map, and standard
  continuity gates.

## Rollback Boundary

Because `.152` is audit-only, rollback removes this note, task-tree/log
updates, README/roadmap/mdBook references, Memory, and Knowledge Map updates.
It does not change parser, generator, PPIF sample, support-accounting,
generated artifact, or HDL behavior.
