# AXI IAL2 Manager Post Read Burst-Last Depth-3 Queue-Head Read-Data Next-Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.160` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.160`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.161`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over the generated read
burst-last depth-3 queue-head read-data shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- `.159` generated read burst-last depth-3 queue-head read-data behavior and
  implementation;
- `.158` read-data readiness audit;
- `.156` generated read burst-last depth-3 response-demux behavior;
- `.153` generated read single-beat depth-3 read-data behavior;
- `.117`, `.119`, and `.121` depth-2 queue-head report-only burst-length,
  runtime-validation, and multi-beat behavior notes;
- `.132` multi-group report-only burst-length behavior;
- current read-data coverage gates, same-ID queue builders, focused tests,
  public PPIF samples, support accounting, README, roadmap, mdBook, task tree,
  Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.159` sample is generated at depth `3`, has scalar last-beat
read-data, and still reports burst-length/beat-count residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=3
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_source=rlast_only
  validation=not_generated
  generated_inputs=axi0_rdata,axi0_rresp
  read_data.residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation
```

The existing depth-2 report-only queue-head burst-length sibling already
generates request-bound raw-`ARLEN` capture without beat counters:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_source=arlen_signal
  validation=report_only
  generated_inputs=axi0_rdata,axi0_rresp,axi0_arlen
  burst_storage=axi0_r0_arlen_q,axi0_r1_arlen_q
  read_data.residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The depth-2 runtime-validation and multi-beat siblings demonstrate the later
follow-on sequence but should not be selected before the report-only
burst-length readiness audit:

```text
depth2 runtime validation:
  validation=runtime_assertion
  burst_storage=axi0_r0_arlen_q,axi0_r1_arlen_q
  beat_storage=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q

depth2 multi-beat:
  capture=multi_beat
  validation=runtime_assertion
  beat_storage=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q
  read_data.residue=
```

## Selection

Select `.161`, readiness audit for generated report-only raw-`ARLEN`
burst-length capture over the generated read burst-last depth-3 queue-head
read-data shape.

The `.161` audit should decide whether an implementation can directly ship a
new public sample that adds only:

- `read-data.read.burst-length` metadata with `source arlen`;
- generated input `axi0_arlen` with width `8`;
- `encoding axlen-plus-one`;
- `capture request`;
- `validation report-only`;
- per-transaction raw-`ARLEN` storage for `r0`, `r1`, and `r2`;
- per-transaction request-guarded raw-`ARLEN` capture rules;
- support-accounting, focused generator and PPIF/CLI coverage, direct
  schedule/check/semantic/verify-HDL probes, docs, mdBook, task tree, Memory,
  and Knowledge Map sync.

The candidate implementation boundary should preserve all `.159` constraints:
read family, `response-scope burst-last`, one-bit `RLAST`, one generated read
burst-last depth-3 queue-head response-demux group, `r0`/`r1`/`r2`, scalar
last-beat `RDATA`/`RRESP` outputs, and
`generated_queue_head_response_demux_last_beat_completion_pulse`.

## Deferred Work

The following remain outside `.161` unless the audit explicitly proves a
smaller prerequisite is needed instead:

- runtime beat-count/`RLAST` validation over read burst-last depth-3
  queue-head read-data;
- multi-beat output-bank behavior over read burst-last depth-3 queue-head
  read-data;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation For This Selector

This selector is documentation-only. The completed slice ran:

- `bash knowledge-map/scripts/gen_knowledge_map.sh`;
- `bash knowledge-map/scripts/check_knowledge_map.sh`;
- `mdbook build docs/book`;
- `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`;
- `scripts/check_memory_architecture.sh`;
- `git --no-pager diff --check`;
- README fast-ramp numbering check through entry `206`;
- stale `.160` frontier scan and positive `.160`/`.161` ownership scan.
