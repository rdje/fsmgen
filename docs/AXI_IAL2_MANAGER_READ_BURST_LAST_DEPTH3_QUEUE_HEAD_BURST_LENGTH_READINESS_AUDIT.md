# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Burst-Length Readiness Audit

Status: audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.161` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.161`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.162`, direct bounded
implementation of generated report-only raw-`ARLEN` burst-length capture over
the generated read burst-last depth-3 queue-head read-data shape.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.160` selector for this readiness audit;
- `.159` generated read burst-last depth-3 queue-head read-data behavior and
  implementation;
- `.158` read-data readiness audit;
- `.117` report-only queue-head burst-length behavior;
- `.119` queue-head runtime-validation behavior;
- `.121` queue-head multi-beat read-data behavior;
- `.132` multi-group report-only burst-length behavior;
- current burst-length normalization, queue-head read-data coverage,
  raw-`ARLEN` storage/rule generation, report helpers, focused generator and
  PPIF/CLI tests, public PPIF samples, support accounting, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.159` sample is generated at depth `3`, has scalar last-beat
read-data, and still defers burst-length/beat-count handling:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=3
  transactions=r0,r1,r2
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_source=rlast_only
  validation=not_generated
  generated_inputs=axi0_rdata,axi0_rresp
  generated_burst_length_storage=
  generated_burst_length_rules=
  read_data.residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation
```

The existing depth-2 report-only queue-head burst-length sibling generates
request-bound raw-`ARLEN` capture without beat counters:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2
  transactions=r0,r1
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_source=arlen_signal
  validation=report_only
  generated_inputs=axi0_rdata,axi0_rresp,axi0_arlen
  generated_burst_length_storage=axi0_r0_arlen_q,axi0_r1_arlen_q
  generated_burst_length_rules=axi0_r0_burst_length_capture,axi0_r1_burst_length_capture
  read_data.residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The multi-group report-only sibling proves the same raw-`ARLEN` artifact path
already flattens more than two covered transactions when the coverage gate
admits them:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  depths=2,2
  transactions=r0,r1,r2,r3
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_source=arlen_signal
  validation=report_only
  generated_inputs=axi0_rdata,axi0_rresp,axi0_arlen
  generated_burst_length_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q,axi0_r3_arlen_q
  generated_burst_length_rules=axi0_r0_burst_length_capture,axi0_r1_burst_length_capture,axi0_r2_burst_length_capture,axi0_r3_burst_length_capture
  read_data.residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

A temporary `/tmp` candidate copied the `.159` sample and added only:

- `read-data.read.burst-length`;
- `source arlen`;
- generated signal `axi0_arlen` with width `8`;
- `encoding axlen-plus-one`;
- `capture request`;
- `max-beats 16`;
- `validation report-only`.

The temporary candidate failed closed at the current local coverage predicate:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head last-beat
coverage requires one or more depth-2 concrete same-ID read queue groups with
no burst_length metadata, report-only burst_length metadata, or
runtime-assertion burst_length metadata, or exactly one depth-3 concrete
same-ID read queue group with no burst_length metadata in this slice
```

Strict check JSON reported the same single error with
`generated_output.emitted: false`. The temporary files were deleted after the
probe.

## Code Findings

The only direct blocker is the local queue-head read-data coverage predicate.
`_read_data_response_demux_transaction_coverage` already admits:

- one-or-more depth-2 groups with no `burst_length`;
- one-or-more depth-2 groups with report-only `burst_length`;
- one-or-more depth-2 groups with runtime-assertion `burst_length`;
- exactly one depth-3 group with no `burst_length`.

It rejects exactly one depth-3 group with report-only `burst_length` because
`last_beat_depth3_coverage` is currently scoped to `!has_burst_length`.

The lower layers needed after admission are already transaction-list driven:

- `_normalize_read_data_burst_length` accepts the public raw-`ARLEN`
  report-only metadata;
- `_normalize_read_data_read` assigns per-transaction raw-`ARLEN` storage and
  capture rule names for every covered transaction;
- `_read_data_source_inputs` adds the generated `axi0_arlen` input when
  burst-length behavior is generated;
- `_read_data_burst_length_storage_lines` and
  `_read_data_burst_length_capture_rule_lines` iterate
  `read.transactions`;
- `_read_data_generated_artifacts` and `_report_read_data` already report
  generated burst-length inputs, storage, and rules from the same transaction
  list;
- focused generator/PPIF helpers already accept an explicit transaction list
  for `assert_read_data_burst_length_report`.

Therefore `.162` can be a direct bounded implementation slice. It should only
widen the coverage gate for the selected report-only raw-`ARLEN` depth-3
shape and update public sample/support/test/docs surfaces around that exact
boundary.

## Selected .162 Boundary

`.162` should implement only:

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
  and `validation report-only`;
- public PPIF sample, support accounting, focused generator and PPIF/CLI
  tests, direct schedule/check/semantic/verify-HDL probes, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map updates.

Expected generated artifacts include:

- generated input `axi0_arlen` alongside `axi0_rdata` and `axi0_rresp`;
- raw `ARLEN` storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- request-guarded capture rules `axi0_r0_burst_length_capture`,
  `axi0_r1_burst_length_capture`, and `axi0_r2_burst_length_capture`;
- existing scalar last-beat read-data capture rules guarded by
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- report residue
  `generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation`;
- no expected-beat storage, beat counters, runtime assertions, multi-beat
  output-bank state, write-family behavior, direct backend lowering, or VHDL.

## Deferred Work

The following remain outside `.162`:

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

## Validation Gates For .162

The implementation slice should run:

- syntax checks for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, focused generator tests, focused PPIF/CLI tests, and
  regression-corpus accounting;
- direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes for the new public PPIF sample;
- preservation probes or focused assertions for `.159`, depth-2 report-only
  burst-length, depth-2 runtime-validation, depth-2 multi-beat, and
  multi-group report-only burst-length siblings;
- focused generator and PPIF/CLI regressions;
- regression-corpus accounting;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and frontier scans.

## Rollback Boundary

Because `.161` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. No behavior-bearing code or public sample is
changed by this slice.

## Validation For This Audit

This audit is documentation-only. The completed slice ran:

- live schedule probes for the `.159`, depth-2 report-only burst-length, and
  multi-group report-only burst-length public samples;
- a temporary depth-3 report-only raw-`ARLEN` candidate schedule/check probe;
- `bash knowledge-map/scripts/gen_knowledge_map.sh`;
- `bash knowledge-map/scripts/check_knowledge_map.sh`;
- `mdbook build docs/book`;
- `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`;
- `scripts/check_memory_architecture.sh`;
- `git --no-pager diff --check`;
- README fast-ramp numbering check through entry `207`;
- stale `.161` frontier scan and positive `.161`/`.162` ownership scan.
