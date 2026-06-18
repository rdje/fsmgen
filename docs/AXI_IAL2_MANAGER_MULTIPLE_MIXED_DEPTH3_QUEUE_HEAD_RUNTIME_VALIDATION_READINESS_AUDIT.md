# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Runtime-Validation Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.185` on
2026-06-18.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.185`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.186`, direct bounded
implementation of generated beat-count/`RLAST` runtime validation over the
generated multiple/mixed depth-3 read burst-last queue-head scalar last-beat
read-data shape that already has report-only raw-`ARLEN` burst-length
capture.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, validation, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.184` selector;
- the `.183` report-only raw-`ARLEN` burst-length behavior and implementation
  boundary;
- the `.182` readiness audit and `.180` no-`burst_length` scalar last-beat
  behavior;
- one-group depth-3 report-only raw-`ARLEN`, runtime-validation, and
  multi-beat behavior notes;
- multi-group depth-2 report-only raw-`ARLEN` and runtime-validation behavior
  notes;
- `_read_data_response_demux_transaction_coverage`, burst-length
  normalization, expected-beat storage, beat-count storage/rule/assertion,
  generated-artifact, report, focused generator, PPIF/CLI, public sample,
  support-accounting, README, roadmap, mdBook, downstream spec, task tree,
  Memory, and Knowledge Map surfaces.

## Live Probe Findings

The two `.183` target samples generate report-only raw-`ARLEN` capture and
preserve explicit `generated_beat_count_validation` residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_validation=report_only
  beat_count_validation_generated_behavior=0
  transactions=6
  generated_expected_beat_count_storage=0
  generated_beat_count_rules=0
  generated_beat_count_assertions=0
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif
  groups=3:3:r0,r1,r2;5:2:r3,r4
  capture=last_beat
  completion=generated_queue_head_response_demux_last_beat_completion_pulse
  burst_length_validation=report_only
  beat_count_validation_generated_behavior=0
  transactions=5
  generated_expected_beat_count_storage=0
  generated_beat_count_rules=0
  generated_beat_count_assertions=0
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The runtime-validation precedents generate the expected-beat and beat-count
substrate from admitted transaction lists:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  groups=3:3:r0,r1,r2
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=1
  transactions=3
  generated_expected_beat_count_storage=3
  generated_beat_count_rules=6
  generated_beat_count_assertions=12
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  groups=3:2:r0,r1;5:2:r2,r3
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=1
  transactions=4
  generated_expected_beat_count_storage=4
  generated_beat_count_rules=8
  generated_beat_count_assertions=16
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The one-group depth-3 multi-beat precedent also depends on generated
runtime-validation state first:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
  capture=multi_beat
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=1
  generated_expected_beat_count_storage=3
  generated_beat_count_rules=6
  generated_beat_count_assertions=12
  residue=
```

Temporary runtime-assertion variants of the two `.183` samples fail closed at
the current last-beat queue-head coverage diagnostic. That confirms the
remaining blocker is the local admission branch, not PPIF parsing,
normalization, generated-artifact projection, report projection, or HDL
lowering.

## Code Findings

`_read_data_response_demux_transaction_coverage` has three relevant
last-beat admission branches:

- no `burst_length` metadata admits depth-2 and depth-3 groups when every
  group has matching transaction count and at least one group has depth `3`;
- report-only `burst_length` metadata admits the same multiple/mixed depth-3
  groups;
- runtime-assertion `burst_length` metadata currently admits all depth-2
  groups and exactly one depth-3 group, but not yet multiple/mixed depth-3
  groups.

Once that coverage function returns a transaction list, the runtime-validation
substrate is not queue-depth specific:

- `_normalize_read_data_burst_length` already normalizes `source arlen`,
  width `8`, `encoding axlen-plus-one`, `capture request`, `max-beats`, and
  `validation runtime-assertion`;
- `_normalize_read_data_read` adds per-transaction raw-`ARLEN`,
  expected-beat, beat-count, rule, and assertion names for
  `runtime_assertion`;
- `_read_data_burst_length_storage_lines` and
  `_read_data_burst_length_capture_rule_lines` emit raw-`ARLEN` state and
  request capture per transaction;
- `_read_data_beat_count_storage_lines` emits expected-beat and read-beat
  counter storage per transaction;
- `_read_data_beat_count_rule_lines` emits request-time expected-beat/counter
  initialization plus raw matched-read-beat increment rules per transaction;
- `_read_data_beat_count_assertion_specs` emits four beat-count/`RLAST`
  assertions per transaction;
- `_read_data_generated_artifacts` and `_report_read_data` project
  generated expected-beat storage, beat-count storage, rules, and assertions
  from the same transaction list.

The existing focused test helpers already have the report-only two-depth-3
and mixed depth-3/depth-2 contract factories and reusable
`assert_read_data_burst_length_report` support for `runtime_assertion`.

## Candidate Comparison

Generated runtime validation over the `.183` shape is ready for a direct
bounded implementation owner:

- `.180` proves generated scalar last-beat `RDATA`/`RRESP` over the target
  depth `3,3` and `3,2` queue sets without `burst_length`;
- `.183` proves report-only raw-`ARLEN` capture over the same transaction
  lists;
- one-group depth-3 proves the depth-3 runtime assertion contract;
- multi-group depth-2 proves runtime-validation helpers scale across more
  than one queue-head group when admitted;
- multi-beat payload over these groups should remain later because the
  per-beat output-bank path depends on this runtime-validation substrate;
- write-family read-data remains a separate public-contract question because
  write responses do not carry `RDATA`;
- same-family mixed auto-ID plus concrete queue-head demux still needs
  allocator/queue interaction semantics;
- group-local simultaneous enqueue widening changes queue transition
  semantics;
- packed burst-vector outputs and alternate full burst assembly are output
  shape work beyond scalar last-beat capture;
- verification-output generation is owned by the IAL1 verification-code
  frontier;
- direct backend, VHDL, and backend-language variants remain deferred until
  the SystemVerilog-backed IAL path is feature complete.

## Selected .186 Boundary

`.186` should implement only generated beat-count/`RLAST` runtime validation
over read burst-last scalar last-beat read-data where every duplicate
concrete `RID` group has computed depth `2` or `3`, at least one group has
depth `3`, and every selected group is already generated by the `.183`
report-only raw-`ARLEN` boundary.

The bounded public samples should be:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
```

Expected support-accounting entries and coverage buckets should follow the
existing naming pattern:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion
ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli
ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli
```

Expected generated-artifact behavior:

- the two-depth-3 sample covers `r0`/`r1`/`r2` and `r3`/`r4`/`r5`, emits six
  raw-`ARLEN` storage signals, six expected-beat storage signals, six
  read-beat counters, six request-time init rules, six matched-beat increment
  rules, 24 beat-count/`RLAST` assertions, 12 scalar last-beat
  data/status outputs, and six scalar read-data capture rules;
- the mixed depth-3/depth-2 sample covers `r0`/`r1`/`r2` and `r3`/`r4`, emits
  five raw-`ARLEN` storage signals, five expected-beat storage signals, five
  read-beat counters, five request-time init rules, five matched-beat
  increment rules, 20 beat-count/`RLAST` assertions, 10 scalar last-beat
  data/status outputs, and five scalar read-data capture rules;
- both samples preserve `generated_read_burst_last_queue_head_demux`,
  one-bit `RLAST`-guarded queue-head completion, completion validity
  `generated_queue_head_response_demux_last_beat_completion_pulse`, scalar
  last-beat capture, and request-time raw-`ARLEN` capture;
- both samples report `burst_length_validation: runtime_assertion`,
  `beat_count_validation_generated_behavior: true`,
  `expected_beat_count_encoding: arlen_plus_one`,
  `beat_count_match_source: response_demux_matched_read_beat`, and
  `beat_count_width: 5`;
- both samples remove `generated_beat_count_validation` from
  `read_data.residue`, while preserving `multi_beat_read_data_reassembly`,
  `per_beat_outputs`, and `rresp_aggregation`.

`.186` must not enable multi-beat output-bank behavior, write-family
read-data, same-family mixed auto-ID plus concrete queue-head demux,
group-local simultaneous enqueue widening, packed burst-vector outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, or another backend-language variant.

## Validation Gates For .186

The implementation leaf should run syntax checks for the touched Perl module
and focused tests, direct schedule/check/semantic/verify-HDL probes for both
new public PPIF samples, focused generator and PPIF/CLI tests, regression
corpus accounting, supported-corpus path/check/semantic gates, Knowledge Map
generation/check, mdBook build, docs relative-path audit, memory architecture
check, diff hygiene, README numbering, and stale/positive frontier scans.

## Rollback Boundary

Because `.185` is readiness-only, rollback is documentation, task-tree,
Memory, and Knowledge Map state only. `.186` should keep the implementation
rollback local to `_read_data_response_demux_transaction_coverage`, the two
public PPIF samples, focused tests, support accounting, generated-reference
expectations, and synchronized docs.
