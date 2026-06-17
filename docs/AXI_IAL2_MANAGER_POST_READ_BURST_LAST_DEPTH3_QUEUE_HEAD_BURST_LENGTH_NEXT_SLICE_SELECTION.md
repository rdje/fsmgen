# AXI IAL2 Manager Post Read Burst-Last Depth-3 Queue-Head Burst-Length Next Slice Selection

Status: selection for `IAL2-FEATURE-COMPLETENESS-FRONTIER.163` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.163`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.164`, a readiness audit for
generated runtime beat-count/`RLAST` validation over the shipped read
burst-last depth-3 queue-head read-data plus report-only raw-`ARLEN`
burst-length shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.162` generated report-only raw-`ARLEN` depth-3 behavior note and
  implementation;
- the `.161` readiness audit that selected `.162`;
- the `.159` no-`burst_length` read burst-last depth-3 queue-head read-data
  behavior;
- the `.119` one-group depth-2 runtime-validation behavior;
- the `.135` multi-group depth-2 runtime-validation behavior;
- the `.121` one-group multi-beat output-bank behavior;
- the `.127` multi-group multi-beat output-bank behavior;
- current queue-head read-data coverage gates, burst-length
  runtime-validation helpers, multi-beat output-bank helpers, focused
  generator and PPIF/CLI tests, public PPIF samples, support accounting,
  README, roadmap, mdBook, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.162` sample remains report-only and keeps runtime validation
deferred:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=3
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  validation=report_only
  generated_burst_length_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q
  generated_expected_beat_count_storage=
  generated_beat_count_storage=
  generated_beat_count_rules=
  read_data.residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The existing one-group depth-2 runtime-validation sample proves the
beat-count path for a generated queue-head last-beat shape:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  validation=runtime_assertion
  beat_count_match_source=response_demux_matched_read_beat
  generated_burst_length_storage=axi0_r0_arlen_q,axi0_r1_arlen_q
  generated_expected_beat_count_storage=axi0_r0_expected_beats_q,axi0_r1_expected_beats_q
  generated_beat_count_storage=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q
  generated_beat_count_rules=axi0_r0_beat_count_init,axi0_r0_read_beat_count,axi0_r1_beat_count_init,axi0_r1_read_beat_count
  read_data.residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The multi-group depth-2 runtime-validation sibling shows the same helper path
already flattens more than two covered transactions when the admission gate
permits the shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  depths=2,2
  validation=runtime_assertion
  beat_count_match_source=response_demux_matched_read_beat
  generated_expected_beat_count_storage=axi0_r0_expected_beats_q,axi0_r1_expected_beats_q,axi0_r2_expected_beats_q,axi0_r3_expected_beats_q
  generated_beat_count_storage=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q,axi0_r2_read_beat_count_q,axi0_r3_read_beat_count_q
  generated_beat_count_rules=axi0_r0_beat_count_init,axi0_r0_read_beat_count,axi0_r1_beat_count_init,axi0_r1_read_beat_count,axi0_r2_beat_count_init,axi0_r2_read_beat_count,axi0_r3_beat_count_init,axi0_r3_read_beat_count
```

The existing one-group depth-2 multi-beat output-bank sample depends on the
same runtime-validation substrate and proves why runtime validation should be
audited before a depth-3 multi-beat selection:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  capture=multi_beat
  validation=runtime_assertion
  beat_count_match_source=response_demux_matched_read_beat
  generated_multi_beat_valid_outputs=axi0_r0_beat_valid,axi0_r1_beat_valid
  read_data.residue=
```

A temporary candidate copied the `.162` PPIF sample and changed only:

```text
(validation report-only)
```

to:

```text
(validation runtime-assertion)
```

Strict check JSON failed closed with `generated_output.emitted: false` and the
current local coverage diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head last-beat
coverage requires one or more depth-2 concrete same-ID read queue groups with
no burst_length metadata, report-only burst_length metadata, or
runtime-assertion burst_length metadata, or exactly one depth-3 concrete
same-ID read queue group with no burst_length metadata or report-only
burst_length metadata in this slice
```

The temporary file was unlinked by the probe process.

## Code Findings

`_read_data_response_demux_transaction_coverage` now admits exactly one
depth-3 read burst-last queue-head group for no `burst_length` metadata or
report-only raw-`ARLEN` metadata. It deliberately still excludes
`runtime_assertion` metadata from the selected depth-3 branch while allowing
runtime assertions for one-or-more depth-2 groups.

Below the admission predicate, the runtime-validation helpers are already
transaction-list driven:

- `_normalize_read_data_read` assigns `expected_beats_q`,
  `read_beat_count_q`, beat-count init rules, increment rules, and assertion
  names per covered transaction when validation is `runtime_assertion`;
- `_read_data_beat_count_storage_lines` and
  `_read_data_beat_count_rule_lines` iterate the normalized transaction list;
- `_read_data_beat_count_assertion_specs` derives the same four assertion
  families per covered transaction;
- `_read_data_generated_artifacts` and `_report_read_data` report generated
  expected-beat storage, counters, rules, and assertion names from the same
  transaction list.

That evidence is strong but not sufficient for direct behavior work without a
readiness audit. The runtime-validation path changes assertions and beat-match
state, while the current candidate still fails at a local admission gate. The
next safe owner is an audit that proves whether direct implementation only
needs the gate widened or whether a smaller prerequisite is required.

## Selected .164 Boundary

`.164` should audit only generated runtime-validation over the `.162` shape:

- read family;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`/`RLAST` metadata;
- generated queue-head response-demux boundary
  `generated_read_burst_last_queue_head_demux`;
- exactly one duplicate concrete read-ID group;
- exactly three read transactions in that group;
- computed queue depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- `read-data.read.capture-scope last-beat`;
- `completion-source response-demux`;
- `status-policy last-beat`;
- `interleaving last-beat-by-rid`;
- scalar `RDATA`/`RRESP` output bindings for `r0`, `r1`, and `r2`;
- `read-data.read.burst-length` with `source arlen`, signal `axi0_arlen`
  width `8`, `encoding axlen-plus-one`, `capture request`, `max-beats 16`,
  and `validation runtime-assertion`;
- expected artifacts if the audit selects direct implementation:
  `axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`,
  `axi0_r2_expected_beats_q`, `axi0_r0_read_beat_count_q`,
  `axi0_r1_read_beat_count_q`, `axi0_r2_read_beat_count_q`, per-transaction
  beat-count init and increment rules, and beat-count/`RLAST` assertion
  names;
- no multi-beat output-bank state, write-family behavior, multiple or mixed
  depth-3 groups, direct backend lowering, or VHDL.

## Deferred Work

The following remain outside `.164`:

- implementation of runtime validation before the audit selects it;
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

## Validation Gates For .164

The audit should run:

- live schedule probes for the `.162` sample, the one-group depth-2
  runtime-validation sample, the multi-group depth-2 runtime-validation
  sample, and the one-group depth-2 multi-beat sample;
- a temporary depth-3 runtime-validation candidate check probe;
- code inspection of queue-head read-data coverage, runtime-validation helper
  normalization, beat-count storage/rule/assertion generation, report
  helpers, focused generator/PPIF tests, support accounting, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and frontier scans.

## Rollback Boundary

Because `.163` is selector-only, rollback is documentation, task-tree,
Memory, and Knowledge Map state only. No behavior-bearing code or public
sample is changed by this slice.

## Validation For This Selector

This selector is documentation-only. The completed slice ran:

- live schedule probes for the `.162` report-only depth-3 sample, the
  one-group depth-2 runtime-validation sample, the multi-group depth-2
  runtime-validation sample, and the one-group depth-2 multi-beat sample;
- a temporary depth-3 runtime-validation candidate strict check JSON probe;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene;
- README fast-ramp numbering check;
- stale `.163` frontier scan and positive `.164` ownership scan.
