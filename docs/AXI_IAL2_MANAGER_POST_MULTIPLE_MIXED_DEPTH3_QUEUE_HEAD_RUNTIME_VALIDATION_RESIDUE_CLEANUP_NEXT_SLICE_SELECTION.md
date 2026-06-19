# AXI IAL2 Manager Post Multiple/Mixed Depth-3 Runtime-Validation Residue Cleanup Next Slice Selection

Status: selection for `IAL2-FEATURE-COMPLETENESS-FRONTIER.189` on
2026-06-19.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.189`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.190`, readiness audit for generated
multi-beat output-bank behavior over multiple/mixed depth-3 read burst-last
queue-head runtime-validation groups.

No parser, generator, PPIF sample, support-accounting, generated-artifact,
test, validation, or HDL behavior changes are made by this selector slice.

## Evidence Read

The selector read:

- the `.188` support/residue cleanup;
- the `.187` selector;
- the `.186` generated multiple/mixed depth-3 runtime-validation behavior;
- the `.185` readiness audit;
- the `.183` report-only raw-`ARLEN` behavior;
- the `.180` no-`burst_length` scalar last-beat behavior;
- one-group depth-3 runtime-validation and multi-beat behavior notes;
- multi-group depth-2 runtime-validation and multi-beat behavior notes;
- `_read_data_response_demux_transaction_coverage`, multi-beat output-bank
  generation/report helpers, focused generator/PPIF tests, public samples,
  support accounting, README, roadmap, mdBook, downstream-facing feature
  backlog, task tree, Memory, and Knowledge Map.

## Live Probe Findings

Compact live probes show the target `.186` samples already generate runtime
validation but still defer the payload/output family:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  validation=runtime_assertion
  beat_count_generated=1
  multi_beat_generated=0
  transactions=r0,r1,r2,r3,r4,r5
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  validation=runtime_assertion
  beat_count_generated=1
  multi_beat_generated=0
  transactions=r0,r1,r2,r3,r4
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The closest shipped multi-beat precedents are residue-clean:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
  mode=bounded_multi_beat_read_data_contract
  capture=multi_beat
  validation=runtime_assertion
  beat_count_generated=1
  multi_beat_generated=1
  capture_rules=48
  transactions=r0,r1,r2
  residue=

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  mode=bounded_multi_beat_read_data_contract
  capture=multi_beat
  validation=runtime_assertion
  beat_count_generated=1
  multi_beat_generated=1
  capture_rules=64
  transactions=r0,r1,r2,r3
  residue=
```

The current local coverage gate still fail-closes the two target
multiple/mixed depth-3 multi-beat group sets with the existing diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head multi-beat
coverage requires one or more depth-2 concrete same-ID read queue groups, or
exactly one depth-3 concrete same-ID read queue group with runtime-assertion
burst_length metadata, in this slice
```

## Selection Rationale

The remaining residue after `.188` is no longer stale report prose; it is a
real behavior gap. The narrowest next owner is a readiness audit for the
multi-beat output-bank path over the exact multiple/mixed depth-3
runtime-validation groups shipped by `.186`.

This should be an audit before implementation because the local gate currently
admits:

- one or more depth-2 queue-head multi-beat groups;
- exactly one depth-3 queue-head multi-beat group with runtime-assertion
  burst-length metadata;
- multiple/mixed depth-3 scalar last-beat groups with no `burst_length`,
  report-only raw-`ARLEN`, or runtime-assertion validation metadata.

It does not yet admit multiple/mixed depth-3 multi-beat groups. The audit must
confirm whether widening that one gate is enough, or whether multi-beat
output-bank artifact/report/test/sample support needs another prerequisite.

The next alternatives remain larger or less local:

- write-family read-data is a separate public-contract question because AXI
  write responses do not carry `RDATA`;
- same-family mixed auto-ID plus concrete queue-head demux changes allocator
  and queue interaction semantics;
- group-local simultaneous enqueue widening changes transition semantics;
- packed burst-vector outputs and alternate full burst assembly are output
  shape work beyond the existing per-beat output-bank contract;
- verification-output generation is owned by the IAL1 verification-code
  frontier;
- direct backend, VHDL, and backend-language variants remain deferred until
  the SystemVerilog-backed IAL path is feature complete.

## Selected .190 Boundary

`.190` should audit readiness for generated multi-beat output-bank behavior
over the two existing `.186` multiple/mixed depth-3 runtime-validation shapes:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
```

The audit must decide whether `.191` can be a direct bounded implementation
owner for new multi-beat public samples, or whether a smaller prerequisite is
needed first.

The audit should examine:

- `_read_data_response_demux_transaction_coverage` and its multi-beat
  admission branch;
- transaction-list driven raw-`ARLEN`, expected-beat, beat-count, lane,
  valid-mask, length, and scalar `RRESP` aggregation helpers;
- report projection for generated multi-beat data/status outputs, capture
  rules, valid masks, length outputs, and `RRESP` aggregates;
- focused generator/PPIF test factories and assertion helpers;
- public PPIF naming and support-accounting naming for two-depth-3 and mixed
  depth-3/depth-2 multi-beat samples;
- preservation of `.186`, `.183`, `.180`, `.168`, `.127`, `.135`, response
  demux-only, single-beat read-data, write response-demux, strict
  check/semantic JSON, generated-artifact, and HDL behavior.

## Deferred Work

The following remain outside `.190`:

- implementation of multi-beat behavior itself;
- write-family read-data;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Validation Gates For .190

The selected audit should run:

- compact schedule probes for the two `.186` runtime-validation samples, the
  one-depth-3 multi-beat sample, and the depth-2 multi-group multi-beat
  sample;
- an admission-gate probe showing current multiple/mixed depth-3 multi-beat
  candidates fail closed at the local multi-beat coverage diagnostic;
- code review over coverage, normalization, generated artifacts, report
  projection, focused tests, public samples, and support accounting;
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map sync; and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.189` task-tree/log updates, live-doc references, Memory, and
Knowledge Map updates. It does not change parser, generator, PPIF sample,
support-accounting, generated artifact, test, validation, or HDL behavior.
