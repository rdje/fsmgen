# AXI IAL2 Manager Post Read Burst-Last Depth-3 Queue-Head Response-Demux Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.157` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.157`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.158`, readiness audit for
generated read-data over read burst-last depth-3 queue-head response-demux.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- `.156` generated read burst-last depth-3 queue-head response-demux behavior
  and implementation;
- `.155` read burst-last depth-3 readiness audit;
- `.153` generated read single-beat depth-3 queue-head read-data behavior;
- `.149` generated read single-beat depth-3 queue-head response-demux
  behavior;
- existing depth-2 read burst-last queue-head read-data, burst-length,
  runtime-validation, multi-beat, read single-beat, and write queue-head
  behavior notes;
- current same-ID queue behavior, read-data coverage, report/residue helpers,
  focused tests, public PPIF samples, support accounting, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.156` sample is generated and remains response-demux-only:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  response_generated=1
  queue_depths=3
  response_residue=read_data_interleaving,bursts
  read_data_mode=none
```

The adjacent shipped read-data samples show the current asymmetry:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  queue_depths=2
  read_data_mode=bounded_last_beat_read_data_contract
  completion_validity=generated_queue_head_response_demux_last_beat_completion_pulse

ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_single_beat_queue_head_demux
  queue_depths=3
  read_data_mode=bounded_single_beat_read_data_contract
  completion_validity=generated_queue_head_response_demux_completion_pulse
```

A temporary `/tmp` probe added last-beat scalar `read-data` bindings for
`r0`, `r1`, and `r2` to the `.156` public sample. The temporary file was
removed after use. It fails closed at the expected coverage gate:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head last-beat
coverage requires one or more depth-2 concrete same-ID read queue groups with
no burst_length metadata, report-only burst_length metadata, or
runtime-assertion burst_length metadata in this slice
```

Strict check JSON reports the same single error, with no generated output.

## Code Finding

`_read_data_response_demux_transaction_coverage` already recognizes
`capture_scope last-beat` over the
`generated_read_burst_last_queue_head_demux` boundary, but its depth-3
exception is currently scoped only to the read single-beat sibling:

- single-beat queue-head read-data accepts one depth-3 group of three
  transactions;
- burst-last queue-head last-beat, report-only burst-length,
  runtime-validation, and multi-beat read-data still require depth-2 queue
  groups.

Downstream read-data generation already consumes generated completion signals
and iterates the covered transaction list once the coverage gate admits a
shape. The safe next step is therefore a focused readiness audit for the
depth-3 burst-last last-beat read-data sibling before any behavior change.

## Selected .158 Boundary

`.158` should audit whether the next implementation can safely support:

- read family only;
- generated read burst-last queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- `read_data.read capture_scope last-beat`;
- `completion_source response-demux`;
- `status_policy last-beat`;
- no `burst_length`, runtime beat-count validation, multi-beat output bank,
  packed payload vector, status aggregation, write depth-3, multiple/mixed
  depth-3 groups, mixed auto-ID, direct backend, or VHDL widening.

The audit must decide whether `.159` can be a direct implementation owner,
whether a smaller report/static prerequisite is needed first, or whether the
shape should defer behind another owner.

## Deferred Work

The following remain outside `.158` unless that audit explicitly selects a
smaller subset:

- implementation of read-data over read burst-last depth-3;
- burst-length metadata over read burst-last depth-3;
- runtime beat-count validation over read burst-last depth-3;
- multi-beat output-bank behavior over read burst-last depth-3;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation Gates For .158

The audit should run or record:

- live schedule probes for `.156`, the depth-2 read burst-last read-data
  sample, and the depth-3 single-beat read-data sample;
- a temporary last-beat read-data-over-`.156` probe to confirm the fail-closed
  diagnostic;
- code review of `_read_data_response_demux_transaction_coverage`,
  read-data source/input/output/rule generation, report/residue helpers,
  focused generator and PPIF/CLI tests, support accounting, docs, and mdBook;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.157` is selector-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. No behavior-bearing code or public sample is
changed by this slice.
