# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Burst-Length Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.182` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.182`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.183`, direct bounded
implementation of generated report-only raw-`ARLEN` burst-length capture over
the generated read burst-last scalar last-beat read-data shape covering
multiple or mixed depth-3 concrete same-ID queue-head groups.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, validation, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.181` selector;
- the `.180` generated multiple/mixed depth-3 read burst-last scalar
  last-beat read-data behavior note and implementation boundary;
- the `.179` readiness audit;
- one-group depth-3 read burst-last report-only burst-length,
  runtime-validation, and multi-beat behavior notes;
- multi-group depth-2 report-only burst-length and runtime-validation
  behavior notes;
- `_read_data_response_demux_transaction_coverage`,
  read-data burst-length normalization, generated signal/storage/rule
  helpers, report projection, focused generator and PPIF/CLI expectations,
  public samples, support accounting, README, roadmap, mdBook, task tree,
  Memory, and Knowledge Map surfaces.

## Live Probe Findings

The `.180` target shape is generated today without `burst_length` metadata:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
  boundary=generated_read_burst_last_queue_head_demux
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  read_data_generated=1
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_source=rlast_only
  burst_length_validation=not_generated
  transactions=6
  generated_outputs=12
  generated_rules=6
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
  boundary=generated_read_burst_last_queue_head_demux
  groups=3:3:r0,r1,r2;5:2:r3,r4
  read_data_generated=1
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_source=rlast_only
  burst_length_validation=not_generated
  transactions=5
  generated_outputs=10
  generated_rules=5
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation,arlen_or_beat_count_validation
```

The one-group depth-3 report-only raw-`ARLEN` precedent is generated:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif
  boundary=generated_read_burst_last_queue_head_demux
  groups=3:3:r0,r1,r2
  burst_length_source=arlen_signal
  burst_length_validation=report_only
  burst_length_generated_behavior=1
  beat_count_validation_generated_behavior=0
  transactions=3
  generated_outputs=6
  generated_rules=6
  generated_burst_length_storage=3
  generated_burst_length_rules=3
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The one-group depth-3 runtime and multi-beat siblings remain generated only
behind runtime-validation metadata:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  burst_length_validation=runtime_assertion
  burst_length_generated_behavior=1
  beat_count_validation_generated_behavior=1
  transactions=3
  generated_burst_length_storage=3
  generated_beat_count_rules=6
  generated_beat_count_assertions=12
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
  capture=multi_beat
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=1
  transactions=3
  generated_outputs=105
  generated_rules=63
  residue=
```

The multi-group depth-2 report-only and runtime-validation precedents are
also generated and transaction-list driven:

```text
ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif
  groups=3:2:r0,r1;5:2:r2,r3
  burst_length_validation=report_only
  transactions=4
  generated_outputs=8
  generated_rules=8
  generated_burst_length_storage=4
  generated_burst_length_rules=4
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  groups=3:2:r0,r1;5:2:r2,r3
  burst_length_validation=runtime_assertion
  transactions=4
  generated_outputs=8
  generated_rules=16
  generated_burst_length_storage=4
  generated_burst_length_rules=4
  generated_beat_count_rules=8
  generated_beat_count_assertions=16
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

## Temporary Candidate Findings

In-memory candidates inserted this report-only metadata into each `.180`
sample without writing temporary files:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

Both candidates fail closed at the existing last-beat coverage gate:

```text
multi-depth3:
  queue-head last-beat coverage requires ... bounded multiple/mixed depth-3
  concrete same-ID read queue groups with no burst_length metadata in this
  slice

mixed-depth3-depth2:
  same diagnostic
```

The failure is therefore the intended local admission boundary, not a parser,
artifact-generation, report-projection, or HDL-lowering prerequisite.

## Code Findings

`_read_data_response_demux_transaction_coverage` already admits the target
multiple/mixed depth-3 queue sets for `capture_scope last-beat` only when
there is no `burst_length` metadata. The adjacent report-only and
runtime-assertion branches still accept all depth-2 groups and exactly one
depth-3 group.

Once a read-data transaction list is admitted, the raw-`ARLEN` substrate is
not queue-depth specific:

- `_normalize_read_data_burst_length` normalizes `source arlen`, width `8`,
  `encoding axlen-plus-one`, `capture request`, `max-beats`, and
  `validation report-only`;
- `_normalize_read_data_read` adds one raw-`ARLEN` storage signal and one
  burst-length capture rule per covered transaction;
- `_read_data_source_inputs` adds the shared generated `axi0_arlen` input;
- `_read_data_burst_length_storage_lines` and
  `_read_data_burst_length_capture_rule_lines` emit storage and request-guarded
  capture rules from the admitted transaction list;
- `_read_data_generated_artifacts` and `_report_read_data` project generated
  burst-length inputs, storage, and rules from the same transaction list;
- scalar last-beat `RDATA`/`RRESP` output and capture-rule helpers are already
  generated for the `.180` transaction lists.

## Candidate Comparison

Report-only raw-`ARLEN` burst-length over the `.180` shape is the smallest
safe implementation owner:

- `.180` proves generated scalar last-beat read-data over the target depth
  `3,3` and `3,2` queue sets with no `burst_length` metadata;
- one-group depth-3 and multi-group depth-2 both added report-only raw
  `ARLEN` before runtime beat-count/`RLAST` validation;
- runtime validation needs raw `ARLEN` and expected-beat state first;
- multi-beat output-bank behavior needs runtime-validation metadata first;
- write-family read-data remains a separate public-contract question because
  write responses do not carry `RDATA`;
- same-family mixed auto-ID plus concrete queue-head demux still needs
  allocator/queue interaction semantics;
- group-local simultaneous enqueue widening changes transition semantics;
- packed burst-vector outputs and alternate full burst assembly are output
  shape work beyond the current scalar and per-beat-bank models;
- verification-output generation is owned by the IAL1 verification-code
  frontier;
- direct backend, VHDL, and backend-language variants remain deferred until
  the SystemVerilog-backed IAL path is feature complete.

## Selected .183 Boundary

`.183` should implement only generated report-only raw-`ARLEN` burst-length
capture over read burst-last scalar last-beat read-data where every duplicate
concrete `RID` group has computed depth `2` or `3`, at least one group has
depth `3`, and every selected group is already generated by the `.180`
read-data boundary.

The bounded public samples should be:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif
```

Expected support-accounting entries and coverage buckets should follow the
existing naming pattern:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length
ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_pipeline_cli
ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_pipeline_cli
```

Expected generated-artifact behavior:

- the two-depth-3 sample covers `r0`/`r1`/`r2` and `r3`/`r4`/`r5`, emits one
  generated `axi0_arlen` input, six raw-`ARLEN` storage signals, six
  request-guarded burst-length capture rules, 12 scalar last-beat
  data/status outputs, and six scalar read-data capture rules;
- the mixed sample covers `r0`/`r1`/`r2` and `r3`/`r4`, emits one generated
  `axi0_arlen` input, five raw-`ARLEN` storage signals, five
  request-guarded burst-length capture rules, 10 scalar last-beat
  data/status outputs, and five scalar read-data capture rules;
- both samples preserve `generated_read_burst_last_queue_head_demux`,
  one-bit `RLAST`-guarded queue-head completion, and completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`;
- both samples report `burst_length_source: arlen_signal`,
  `burst_length_validation: report_only`,
  `burst_length_generated_behavior: true`, and `read_data.residue` of
  `generated_beat_count_validation`, `multi_beat_read_data_reassembly`,
  `per_beat_outputs`, and `rresp_aggregation`;
- both samples omit expected-beat storage, matched-beat counters,
  beat-count/`RLAST` runtime assertions, multi-beat output banks, packed
  payload vectors, and write-family read-data.

Preservation expectations:

- existing depth-2 one-group and multi-group last-beat read-data,
  report-only burst-length, runtime-validation, and multi-beat samples remain
  generated and support-accounted;
- existing one-group depth-3 read burst-last last-beat read-data,
  report-only burst-length, runtime-validation, and multi-beat samples remain
  generated and support-accounted;
- existing `.174` response-demux-only multiple/mixed depth-3 samples remain
  generated and support-accounted;
- existing `.177` read single-beat multiple/mixed depth-3 read-data samples
  remain generated and support-accounted;
- the `.180` no-`burst_length` samples remain generated and continue to omit
  `axi0_arlen`;
- write queue-head response-demux samples and existing HDL verification
  behavior remain unchanged.

`.183` must not enable runtime beat-count/`RLAST` validation, multi-beat
payload behavior, write-family read-data, same-family mixed auto-ID plus
concrete queue-head demux, group-local simultaneous enqueue widening, packed
burst-vector outputs, alternate burst assembly, direct backend,
verification-output generation, VHDL, or another backend-language variant.

## Validation Gates For .183

The implementation should run syntax checks for touched Perl modules and
tests, direct schedule/check/semantic/verify-HDL probes for the two new public
samples, preservation probes for the `.180` no-`burst_length` samples,
one-group depth-3 burst-length/runtime/multi-beat samples, multi-group
depth-2 burst-length/runtime samples, focused generator and PPIF/CLI tests,
regression-corpus accounting, supported-corpus check and semantic gates,
Knowledge Map generation/check, mdBook build, docs relative-path audit,
memory architecture check, diff hygiene, README numbering, and
stale/positive frontier scans.

## Rollback Boundary

Because `.182` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only. `.183` owns the future behavior change and must
keep implementation localized to report-only raw-`ARLEN` last-beat read-data
coverage plus public samples, support accounting, tests, and user-facing docs
unless its own evidence selects a smaller prerequisite first.
