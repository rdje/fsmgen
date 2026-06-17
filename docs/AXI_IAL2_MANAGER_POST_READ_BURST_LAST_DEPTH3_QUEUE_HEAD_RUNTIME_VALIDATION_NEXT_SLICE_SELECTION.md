# AXI IAL2 Manager Post Read Burst-Last Depth-3 Queue-Head Runtime Validation Next Slice Selection

Status: selection for `IAL2-FEATURE-COMPLETENESS-FRONTIER.166` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.166`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.167`, a readiness audit for
generated multi-beat read-data output-bank behavior over the shipped read
burst-last depth-3 queue-head runtime-validation shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.165` generated read burst-last depth-3 queue-head runtime-validation
  behavior note and implementation;
- the `.164` readiness audit that selected `.165`;
- the `.162` report-only raw-`ARLEN` depth-3 behavior;
- the `.159` no-`burst_length` read burst-last depth-3 read-data behavior;
- the `.121` one-group depth-2 queue-head multi-beat behavior;
- the `.127` multi-group depth-2 queue-head multi-beat behavior;
- current queue-head read-data coverage gates, runtime-validation helpers,
  multi-beat output-bank helpers, focused generator and PPIF/CLI tests, public
  PPIF samples, support accounting, README, roadmap, mdBook, task tree,
  Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.165` sample is generated at depth `3` and the remaining
read-data residue is exactly the multi-beat/read-output surface:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  mode=bounded_last_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=runtime_assertion
  beat_count=1
  beat_match=response_demux_matched_read_beat
  output_shape=
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
  queues=3:r0/r1/r2:d3
```

The report-only `.162` sibling remains preserved and still keeps generated
beat-count validation residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
  mode=bounded_last_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=report_only
  beat_count=
  beat_match=
  output_shape=
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
  queues=3:r0/r1/r2:d3
```

The existing one-group depth-2 queue-head multi-beat sample proves the target
output-bank behavior over the same generated burst-last queue-head demux and
runtime-validation substrate:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  mode=bounded_multi_beat_read_data_contract
  generated=1
  boundary=generated_read_burst_last_queue_head_demux
  validation=runtime_assertion
  beat_count=1
  beat_match=response_demux_matched_read_beat
  output_shape=per_beat_output_bank
  residue=
  queues=3:r0/r1:d2
```

A temporary in-memory candidate changed the `.165` sample to
`capture-scope multi-beat` with per-beat outputs and status aggregation. It
failed closed at the current local coverage diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head multi-beat
coverage requires one or more depth-2 concrete same-ID read queue groups in
this slice
```

Code inspection found that, after admission, multi-beat normalization and
rule/report generation are transaction-list driven: output prefixes, valid
masks, length outputs, `beat_match_source response_demux_matched_read_beat`,
request-time output-bank initialization, matched-read-beat lane capture, and
optional scalar `RRESP` aggregation all iterate covered transactions. The
known blocker is therefore the local multi-beat queue-head admission boundary,
but the depth-3 output-bank surface is broad enough to justify a readiness
audit before behavior changes.

## Selection

Select `.167`, readiness audit for generated multi-beat output-bank behavior
over exactly one read burst-last depth-3 queue-head runtime-validation group.

The `.167` audit boundary should evaluate:

- read family only;
- `response-demux.read.response_scope` is `burst-last`;
- the generated queue-head boundary is
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth is `3`;
- `read-data.read.capture_scope` is `multi-beat`;
- `read-data.read.completion_source` is `response-demux`;
- `read-data.read.status_policy` is `per-beat`;
- `read-data.read.interleaving` is `multi-beat-by-rid`;
- `read-data.read.burst-length` uses `source arlen`, signal width `8`,
  `encoding axlen-plus-one`, `capture request`, and
  `validation runtime-assertion`;
- transaction bindings use `data-output-prefix`, `status-output-prefix`,
  `valid-mask-output`, and `length-output`;
- optional scalar `RRESP` aggregation uses per-transaction
  `status-aggregate-output` bindings;
- lane capture uses raw matched queue-head read beats from
  `response_demux_matched_read_beat`;
- dequeue and transaction completion remain owned by the generated queue-head
  demux last-beat completion pulse.

The audit must decide whether direct implementation can widen only the local
coverage gate or whether a smaller prerequisite is required first. It should
record expected sample, support-accounting, report, generated-artifact, test,
documentation, and rollback boundaries before any behavior changes.

## Deferred Work

`.166` does not enable multi-beat over read burst-last depth-3, write depth-3,
multiple or mixed depth-3 groups, mixed auto-ID plus concrete queue-head
demux, group-local enqueue widening, packed outputs, alternate burst payload
assembly, direct backend lowering, verification-output generation, VHDL, or
other backend-language variant implementation.
