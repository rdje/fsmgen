# AXI IAL2 Manager Post Read Single-Beat Depth-3 Queue-Head Read-Data Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.154` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.154`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.155`, readiness audit for generated
read burst-last depth-3 concrete same-ID queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- `.153` generated scalar read-data over read single-beat depth-3 queue-head
  response-demux behavior;
- `.152` read-data-over-depth-3 readiness audit;
- `.149` generated read single-beat depth-3 response-demux behavior;
- `.148` deeper queue-head groups readiness audit;
- adjacent depth-2 read burst-last, write, and read single-beat one-group and
  multi-group queue-head response-demux/read-data behavior notes;
- current response-demux normalization, same-ID queue behavior, read-data
  coverage, report/residue, generated rule, and assertion helpers;
- focused generator and PPIF/CLI tests, public PPIF samples, support
  accounting, README, roadmap, mdBook, task tree, Memory, and Knowledge Map.

## Live Report Findings

The shipped depth-3 read single-beat read-data sample remains generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_single_beat_queue_head_demux
  response_scope=single_beat
  queue_depths=3
  queue_transactions=r0,r1,r2
  read_data_completion=generated_queue_head_response_demux_completion_pulse
  read_data_rules=axi0_r0_read_data_capture,axi0_r1_read_data_capture,axi0_r2_read_data_capture
```

The adjacent read burst-last multi-group sample remains generated only for
depth-2 groups:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  response_scope=burst_last
  last_signal=axi0_rlast
  queue_depths=2,2
  queue_transactions=r0,r1;r2,r3
```

The adjacent write multi-group sample also remains generated only for depth-2
groups:

```text
ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  response_boundary=generated_write_bid_queue_head_demux
  queue_depths=2,2
  queue_transactions=w0,w1;w2,w3
```

## Code Findings

`_build_same_id_issue_order_queue_behavior` now has a generalized queue-state
core for generated queue-head shapes, but its public depth gate still admits
only:

- any supported depth-2 group with exactly two transactions; or
- exactly one read single-beat depth-3 group with exactly three transactions.

That means read burst-last depth-3 and write depth-3 are still intentionally
selected-not-generated. The read burst-last path is the next best audit target
because the existing depth-2 read burst-last response-demux path already owns
`RLAST` metadata, last-signal matching, queue-head completion-pulse semantics,
assertion helpers, read-data follow-on behavior, burst-length metadata, runtime
validation, and multi-beat output-bank follow-on behavior. The depth-3 queue
state machinery is now proven by the read single-beat depth-3 response-demux
and scalar read-data siblings, but the `RLAST`-qualified depth-3 path still
deserves its own readiness audit before generation is widened.

## Selected .155 Boundary

`.155` should audit, without behavior changes, whether the next implementation
owner can safely generate:

- read family only;
- `response-demux.read.response_scope burst-last`;
- one-bit `last-signal` / `RLAST` metadata;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group with three read transactions at
  computed depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- queue-head completion pulses only for the active head transaction whose
  concrete `RID` matches the raw response ID and whose `RLAST` is asserted;
- schedule/check/semantic/report/HDL expectations and preservation probes for
  existing depth-2 burst-last, write, read single-beat, read-data,
  burst-length, runtime-validation, and multi-beat queue-head samples.

The audit must decide whether the following owner can directly implement that
bounded shape or whether another prerequisite is needed first.

## Deferred Work

The following remain outside `.155` unless a later task explicitly selects
them:

- write depth-3 response-demux;
- read-data over read burst-last depth-3 response-demux;
- burst-length, runtime-validation, or multi-beat read-data over read
  burst-last depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- packed burst-vector outputs or alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .154

Because `.154` is selector-only, validation is documentation and continuity
focused:

- live schedule-report probes for the `.153` depth-3 read-data sample and
  adjacent depth-2 read burst-last/write queue-head samples;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene.

## Rollback Boundary

Rollback for `.154` is documentation, task-tree, Memory, and Knowledge Map
state only. No behavior-bearing files, public PPIF samples, tests, generated
artifacts, or HDL outputs are changed by this selector slice.
