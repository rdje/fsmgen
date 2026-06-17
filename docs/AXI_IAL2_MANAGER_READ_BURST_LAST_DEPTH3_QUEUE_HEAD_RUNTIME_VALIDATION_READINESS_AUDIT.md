# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Runtime-Validation Readiness Audit

Status: audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.164` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.164`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.165`, direct bounded
implementation of generated runtime beat-count/`RLAST` validation over the
generated read burst-last depth-3 queue-head read-data plus raw-`ARLEN`
burst-length shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.163` selector for this readiness audit;
- the `.162` report-only raw-`ARLEN` depth-3 behavior and implementation;
- the `.161` report-only raw-`ARLEN` readiness audit;
- the `.159` no-`burst_length` read burst-last depth-3 queue-head read-data
  behavior;
- the `.119` one-group depth-2 queue-head runtime-validation behavior;
- the `.135` multi-group depth-2 queue-head runtime-validation behavior;
- the `.121` one-group depth-2 multi-beat output-bank behavior;
- the `.127` multi-group depth-2 multi-beat output-bank behavior;
- current queue-head read-data coverage gates, burst-length
  runtime-validation normalization, beat-count storage/rule/assertion
  generation, report helpers, focused generator and PPIF/CLI tests, public
  PPIF samples, support accounting, README, roadmap, mdBook, task tree,
  Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.162` report-only sample is generated at depth `3`, covers
`r0`, `r1`, and `r2`, and still leaves runtime validation as residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=3
  tx=r0,r1,r2
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  validation=report_only
  arlen_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q
  expected=
  counters=
  beat_rules=
  assertions=
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The one-group depth-2 runtime-validation sample proves the generated
queue-head last-beat runtime-validation artifacts:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2
  tx=r0,r1
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  validation=runtime_assertion
  beat_match=response_demux_matched_read_beat
  arlen_storage=axi0_r0_arlen_q,axi0_r1_arlen_q
  expected=axi0_r0_expected_beats_q,axi0_r1_expected_beats_q
  counters=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q
  beat_rules=axi0_r0_beat_count_init,axi0_r0_read_beat_count,axi0_r1_beat_count_init,axi0_r1_read_beat_count
  assertions=axi0_r0_arlen_within_max,...,axi0_r1_expected_final_beat_has_rlast
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The multi-group depth-2 runtime-validation sample proves the same helper path
already flattens four covered transactions when the admission gate allows the
shape:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  depths=2,2
  tx=r0,r1,r2,r3
  validation=runtime_assertion
  beat_match=response_demux_matched_read_beat
  expected=axi0_r0_expected_beats_q,axi0_r1_expected_beats_q,axi0_r2_expected_beats_q,axi0_r3_expected_beats_q
  counters=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q,axi0_r2_read_beat_count_q,axi0_r3_read_beat_count_q
```

The one-group depth-2 multi-beat sample is residue-clean and depends on the
same matched-read-beat counter substrate:

```text
ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
  capture=multi_beat
  validation=runtime_assertion
  beat_match=response_demux_matched_read_beat
  multi_valid=axi0_r0_beat_valid,axi0_r1_beat_valid
  residue=
```

A temporary depth-3 runtime-validation candidate copied the `.162` sample and
changed only `(validation report-only)` to `(validation runtime-assertion)`.
Strict check JSON failed closed with `generated_output.emitted: false` and:

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

The only direct blocker is the local queue-head read-data coverage predicate.
`_read_data_response_demux_transaction_coverage` currently admits exactly one
depth-3 read burst-last group for no `burst_length` metadata or report-only
raw-`ARLEN` metadata, but not for `runtime_assertion` metadata.

After admission, the runtime-validation path is already driven by the covered
transaction list:

- `_normalize_read_data_read` assigns `expected_beats_q`,
  `read_beat_count_q`, beat-count init rules, increment rules, and four
  beat-count/`RLAST` assertion names per transaction when validation is
  `runtime_assertion`;
- `_read_data_beat_count_storage_lines` emits expected-beat and read-beat
  counter state for every covered transaction;
- `_read_data_beat_count_rule_lines` emits request-time initialization and
  matched-read-beat counter increment rules for every covered transaction;
- `_read_data_beat_count_assertion_specs` emits request-time `ARLEN` bound,
  extra-beat, early-`RLAST`, and missing-final-`RLAST` assertions for every
  covered transaction;
- `_read_data_generated_artifacts` and `_report_read_data` collect generated
  expected-beat storage, beat counters, rules, and assertions from the same
  transaction list.

Therefore `.165` can be a direct bounded implementation slice. It should only
widen admission for the selected one-group depth-3 runtime-validation shape
and add the public support-accounted sample plus focused coverage around that
exact boundary.

## Selected .165 Boundary

`.165` should implement only:

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
- a public support-accounted PPIF sample, expected to be named
  `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`;
- focused generator and PPIF/CLI tests, direct schedule/check/semantic/HDL
  probes, README, roadmap, mdBook, task tree, Memory, and Knowledge Map
  updates.

Expected generated artifacts include:

- generated `axi0_arlen` input alongside `axi0_rid`, `axi0_rlast`,
  `axi0_rdata`, and `axi0_rresp`;
- raw `ARLEN` storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- request-guarded burst-length capture rules for `r0`, `r1`, and `r2`;
- expected-beat storage `axi0_r0_expected_beats_q`,
  `axi0_r1_expected_beats_q`, and `axi0_r2_expected_beats_q`;
- read-beat counters `axi0_r0_read_beat_count_q`,
  `axi0_r1_read_beat_count_q`, and `axi0_r2_read_beat_count_q`;
- beat-count init and matched-read-beat increment rules for `r0`, `r1`, and
  `r2`;
- four beat-count/`RLAST` assertions per transaction;
- scalar last-beat read-data capture rules still guarded by generated
  queue-head last-beat completion pulses;
- report `beat_count_match_source: response_demux_matched_read_beat`;
- `read_data.residue` keeps `multi_beat_read_data_reassembly`,
  `per_beat_outputs`, and `rresp_aggregation`, but removes
  `generated_beat_count_validation`.

## Deferred Work

The following remain outside `.165`:

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

## Validation Gates For .165

The implementation slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, focused generator tests, focused PPIF/CLI tests, and
  regression-corpus accounting;
- direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes for the new public runtime-validation PPIF sample;
- preservation probes or focused assertions for `.162` report-only depth-3,
  `.159` no-`burst_length` depth-3, one-group depth-2 runtime-validation,
  multi-group depth-2 runtime-validation, and one-group depth-2 multi-beat
  siblings;
- focused generator and PPIF/CLI regressions;
- regression-corpus accounting;
- supported-corpus path/check/semantic gates when support accounting changes;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and frontier scans.

## Rollback Boundary

Because `.164` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. No behavior-bearing code or public sample is
changed by this slice.

## Validation For This Audit

This audit is documentation-only. The completed slice ran:

- live schedule probes for the `.162` report-only depth-3 sample, the
  one-group depth-2 runtime-validation sample, the multi-group depth-2
  runtime-validation sample, and the one-group depth-2 multi-beat sample;
- a temporary depth-3 runtime-validation candidate strict check JSON probe;
- code inspection of the coverage predicate, runtime-validation
  normalization, beat-count storage/rule/assertion generation, and report
  artifact helpers;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene;
- README fast-ramp numbering check;
- stale `.164` frontier scan and positive `.165` ownership scan.
