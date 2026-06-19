# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Multi-Beat Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.190` on
2026-06-19.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.190`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.191`, direct bounded
implementation of generated multi-beat read-data output-bank behavior over the
two existing multiple/mixed depth-3 read burst-last queue-head
runtime-validation shapes.

No parser, generator, PPIF sample, support-accounting, generated-artifact,
validation, test, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- the `.189` selector and `.188` support-residue cleanup;
- the `.186` runtime-validation behavior over multiple/mixed depth-3
  queue-head scalar last-beat read-data;
- the `.185` runtime-validation readiness audit;
- the `.183` report-only raw-`ARLEN` behavior and `.180` no-`burst_length`
  scalar last-beat behavior;
- the one-depth-3 multi-beat output-bank behavior;
- the depth-2 multi-group multi-beat output-bank behavior and depth-2
  multi-group runtime-validation behavior;
- `_read_data_response_demux_transaction_coverage`,
  `_read_data_generated_artifacts`, focused multi-beat generator assertions,
  PPIF/CLI/support-accounting surfaces, README, roadmap, mdBook, downstream
  spec, task tree, Memory, and Knowledge Map surfaces.

## Live Findings

The `.186` two-depth-3 runtime-validation sample already generates the queue
state, scalar last-beat read-data capture, raw-`ARLEN` capture, expected-beat
state, read-beat counters, request/response rules, and beat-count/`RLAST`
assertions for all six transactions:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  groups=3:3:r0,r1,r2;5:3:r3,r4,r5
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  validation=runtime_assertion
  transactions=r0,r1,r2,r3,r4,r5
  beat_count_generated=1
  multi_beat_generated=0
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The `.186` mixed depth-3/depth-2 runtime-validation sample has the same
generated runtime substrate for five transactions:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
  groups=3:3:r0,r1,r2;5:2:r3,r4
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  validation=runtime_assertion
  transactions=r0,r1,r2,r3,r4
  beat_count_generated=1
  multi_beat_generated=0
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The one-depth-3 multi-beat precedent proves the depth-3 runtime-validation
substrate feeds generated per-beat output-bank behavior:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
  groups=3:3:r0,r1,r2
  mode=bounded_multi_beat_read_data_contract
  capture=multi_beat
  validation=runtime_assertion
  transactions=r0,r1,r2
  generated_multi_beat_capture_rules=48
  residue=
```

The depth-2 multi-group multi-beat precedent proves the downstream output-bank
helpers already scale across more than one queue-head group when admitted:

```text
ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  groups=3:2:r0,r1;5:2:r2,r3
  mode=bounded_multi_beat_read_data_contract
  capture=multi_beat
  validation=runtime_assertion
  transactions=r0,r1,r2,r3
  generated_multi_beat_capture_rules=64
  residue=
```

Direct in-memory admission-gate probes for the two target multi-beat group
sets still fail closed at the local coverage diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head multi-beat
coverage requires one or more depth-2 concrete same-ID read queue groups, or
exactly one depth-3 concrete same-ID read queue group with runtime-assertion
burst_length metadata, in this slice
```

That diagnostic is local to the coverage predicate. It does not point to a
parser, normalization, artifact projection, report projection, support
accounting, HDL, IAL1, IAL0, or SystemVerilog prerequisite.

## Code Findings

`_read_data_response_demux_transaction_coverage` already admits the target
multiple/mixed depth-3 queue-head group sets for scalar last-beat read-data
without `burst_length`, report-only raw-`ARLEN`, and runtime-assertion
beat-count/`RLAST` validation. Its multi-beat branch currently admits any
depth-2 queue-head groups and exactly one depth-3 queue-head group with
runtime-assertion burst-length metadata. The remaining behavior gate is the
multi-beat depth-3 group-set admission condition.

After admission, the target behavior is transaction-list driven:

- `_normalize_read_data_read` already expands multi-beat output prefixes,
  generated lane names, valid masks, length outputs, scalar `RRESP`
  aggregation, raw-`ARLEN` metadata, expected-beat state, read-beat counters,
  and runtime assertions for every covered transaction;
- `_read_data_multi_beat_output_init_rule_lines` emits one output-bank clear
  rule per covered transaction;
- `_read_data_capture_rule_lines` emits per-lane capture rules from
  `response_demux_matched_read_beat` and each transaction's read-beat counter;
- `_read_data_generated_artifacts` iterates `read.transactions` for
  multi-beat data/status outputs, valid masks, length outputs, capture rules,
  scalar aggregate outputs, raw-`ARLEN` storage, expected-beat/read-beat
  storage, beat-count rules, and beat-count/`RLAST` assertions;
- `assert_read_data_multi_beat_report` already accepts an explicit
  `transactions => [...]` list and derives output names/counts from it.

## Selected .191 Boundary

`.191` should implement only:

- read family only;
- `response-demux.read.response-scope burst-last`;
- generated queue-head response-demux with one-bit `RLAST` completion;
- duplicate concrete `RID` queue-head groups with computed depth `2` or `3`;
- at least one depth-3 group;
- the exact depth-set shapes already covered by `.186`: depth `3,3` and
  mixed depth `3,2`;
- `read-data.read.capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation (policy worst-observed)`;
- `interleaving multi-beat-by-rid`;
- `burst-length` metadata with `source arlen`, width `8`,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- public support-accounted PPIF samples, focused generator and PPIF/CLI
  expectations, direct schedule/check/semantic/HDL probes, README, roadmap,
  mdBook, task tree, Memory, and Knowledge Map updates.

Expected public samples:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
```

Expected support-accounting entries and coverage buckets:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data
ial2_ppif_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_pipeline_cli
```

Expected generated-artifact/report movement:

- the two-depth-3 sample covers transactions `r0` through `r5`, emits six raw
  `ARLEN` storage signals, six expected-beat storage signals, six read-beat
  counters, twelve beat-count rules, twenty-four beat-count/`RLAST`
  assertions, six output-bank init rules, 96 multi-beat capture rules, 96
  `RDATA` lane outputs, 96 `RRESP` lane outputs, six valid masks, six length
  outputs, and six scalar `RRESP` aggregate outputs;
- the mixed depth-3/depth-2 sample covers transactions `r0` through `r4`,
  emits five raw `ARLEN` storage signals, five expected-beat storage signals,
  five read-beat counters, ten beat-count rules, twenty beat-count/`RLAST`
  assertions, five output-bank init rules, 80 multi-beat capture rules, 80
  `RDATA` lane outputs, 80 `RRESP` lane outputs, five valid masks, five
  length outputs, and five scalar `RRESP` aggregate outputs;
- both samples should report
  `read_data.mode: bounded_multi_beat_read_data_contract`,
  `read_data.read.output_shape: per_beat_output_bank`,
  `read_data.read.burst_length.validation: runtime_assertion`,
  empty `read_data.residue`, and empty `response_demux.residue`;
- both samples preserve generated queue-head demux, one-bit `RLAST`
  completion pulses, strict check/semantic JSON, and HDL generation.

## Preservation Matrix

`.191` must preserve:

- existing `.186` scalar last-beat runtime-validation samples and their
  remaining multi-beat/output/aggregation residue;
- `.183` report-only and `.180` no-`burst_length` multiple/mixed depth-3
  scalar last-beat samples;
- one-depth-3 multi-beat behavior;
- depth-2 multi-group multi-beat and runtime-validation behavior;
- read single-beat and read burst-last response-demux-only depth-3 group
  behavior;
- write-family queue-head behavior;
- support-accounting identities for existing samples;
- generated-artifact names, report schema, strict check/semantic JSON, and
  HDL output for all existing corpus entries.

## Validation Gates For .191

The implementation slice should run:

- syntax checks for every touched Perl module and test;
- direct schedule/check/semantic/`--verify-hdl` probes for the two new PPIF
  samples;
- focused generator test `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- PPIF/CLI test `t/1436-ial2-ppif-parser-cli.t`;
- support-accounting catalog and supported-corpus gates if new support entries
  are added;
- Knowledge Map generation/check, mdBook build, docs relative-path audit,
  memory-architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Deferred Work

The following remain outside `.191`:

- write-family read-data semantics;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Rollback Boundary

Rollback should be local to the multi-beat admission predicate in
`_read_data_response_demux_transaction_coverage`, the two new PPIF samples,
support-accounting entries, focused generator/PPIF expectations, and the
documentation/Knowledge Map/Memory updates. It should not affect parser syntax,
normalization, queue-state helpers, generated runtime-validation helpers, HDL
lowering, or previously shipped samples.
