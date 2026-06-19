# AXI IAL2 Manager Post Multiple/Mixed Depth-3 Queue-Head Runtime Validation Next Slice Selection

Status: selection for `IAL2-FEATURE-COMPLETENESS-FRONTIER.187` on
2026-06-19.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.187`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.188`, AXI manager
report/static support-residue cleanup after generated runtime
beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head scalar
last-beat read-data.

No parser, generator, PPIF sample, support-accounting catalog, validation,
generated-artifact, test, or HDL behavior changes are made by this selector
slice.

## Evidence Read

The selector read:

- the `.186` generated runtime-validation behavior note and implementation
  boundary;
- the `.185` readiness audit that selected `.186`;
- the `.183` report-only raw-`ARLEN` burst-length behavior;
- the `.180` no-`burst_length` scalar last-beat read-data behavior;
- the one-group depth-3 runtime-validation and multi-beat output-bank
  precedents;
- the multi-group depth-2 runtime-validation and support-residue cleanup
  precedent;
- `_read_data_response_demux_transaction_coverage`, generated read-data
  report/static support-detail text, focused PPIF/CLI expectations, README,
  roadmap, mdBook, downstream spec, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The two shipped `.186` public samples generate runtime validation and keep
only the payload/output/aggregation residue in their `read_data` reports:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=true
  read_data.residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
  burst_length_validation=runtime_assertion
  beat_count_validation_generated_behavior=true
  read_data.residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The same schedule reports still expose stale static support wording through
the AXI ID/order unsupported-residue detail. That detail describes selected
multiple/mixed depth-3 read burst-last queue-head groups as supported only
with no `burst_length` metadata or report-only raw-`ARLEN` metadata, and it
still says:

```text
read burst-last read-data consumption over multiple or mixed depth-3
queue-head groups with runtime validation or multi-beat payload
```

remain outside the capacity/status shell.

The runtime-validation half of that phrase is stale after `.186`; the
multi-beat payload half remains accurate. This is report/static support-detail
drift, not behavior drift.

## Selection Rationale

Generated multi-beat output-bank behavior over the multiple/mixed depth-3
runtime-validation groups remains the next behavior-family candidate, but it
should not be selected before the shipped runtime-validation support detail is
truthful.

The closest precedent is
`docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`.
After `.135` shipped multi-group runtime-validation scalar last-beat
read-data, `.136` selected `.137` to clean stale report/static residue before
continuing behavior expansion. The same shape exists here: live behavior is
generated, while the support-detail wording still classifies part of that
behavior as unsupported residue.

## Selected .188 Boundary

`.188` should update only support/report static wording and focused
expectations so generated runtime beat-count/`RLAST` validation over selected
multiple/mixed depth-3 queue-head scalar last-beat read-data is described as
supported, not residue.

The implementation boundary is:

- update the capability/report static support detail in the AXI manager
  capacity/status shell;
- update focused PPIF/CLI assertions so the stale runtime-validation wording
  is rejected, while multi-beat payload over multiple/mixed depth-3 groups
  remains explicit residue;
- preserve live behavior for `.186` runtime-validation samples, `.183`
  report-only samples, `.180` no-`burst_length` samples, one-group depth-3
  runtime/multi-beat samples, multi-group depth-2 runtime/multi-beat samples,
  response-demux-only samples, single-beat read-data samples, write
  response-demux samples, support-accounting identity, generated artifacts,
  strict check/semantic JSON, and HDL generation;
- do not broaden parser syntax, queue-head admission, generated read-data
  rules, generated assertions, PPIF corpus membership, support-accounting
  counts, or generated HDL behavior.

## Deferred Work

The following remain future exact-owner work:

- multi-beat output-bank behavior over multiple/mixed depth-3 runtime
  groups;
- write-family read-data;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.

## Validation Gates For .188

The selected implementation should run:

- syntax checks for touched Perl and test files;
- focused PPIF/CLI support-detail assertions;
- compact schedule probes for `.186`, `.183`, `.180`, one-group depth-3, and
  multi-group depth-2 preservation samples;
- a stale-phrase scan proving the retired runtime-validation unsupported
  wording is absent from code/tests/docs that describe current support;
- mdBook, README, roadmap, downstream spec if needed, task tree, Memory, and
  Knowledge Map sync; and
- standard continuity gates before commit.

## Rollback Boundary

This selector is documentation/task-tree state only. Rolling it back removes
this note, the `.187` task-tree/log updates, live-doc references, Memory, and
Knowledge Map card. It does not change parser, generator, PPIF sample,
support-accounting catalog, validation, generated artifact, test, or HDL
behavior.
