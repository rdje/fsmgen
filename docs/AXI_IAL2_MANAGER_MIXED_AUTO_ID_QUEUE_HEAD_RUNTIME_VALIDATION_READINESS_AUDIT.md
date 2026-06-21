# AXI IAL2 Manager Mixed Auto-ID Queue-Head Runtime-Validation Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.201` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.201`

Superseding note: this audit selected `.202`; `.202` now ships the selected
runtime behavior in
`docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`.

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.202`, direct bounded
implementation of generated runtime beat-count/`RLAST` validation over the
same-family mixed auto-ID plus concrete same-ID queue-head read burst-last
scalar last-beat read-data shape that `.200` already ships with report-only
raw-`ARLEN` capture.

No parser, generator, PPIF sample, support-accounting catalog, test,
generated-artifact, validation, or HDL behavior changes are made by this audit
slice.

## Evidence Read

The audit read:

- `.200` mixed report-only raw-`ARLEN` burst-length behavior;
- `.199` mixed burst-length readiness audit;
- `.197` mixed scalar read-data behavior;
- `.194` same-family mixed auto-ID plus concrete queue-head response-demux
  behavior;
- one-group queue-head runtime-validation behavior;
- depth-3 and multiple/mixed depth-3 queue-head runtime-validation readiness
  and behavior precedents;
- runtime beat-count helper code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`;
- PPIF burst-length validation syntax, support/residue/report surfaces,
  README, ROADMAP_V2, mdBook, public contract/handoff docs, task tree,
  Memory, and Knowledge Map entries.

## Live Probe Findings

The `.200` public report-only mixed sample still emits report-only
raw-`ARLEN` metadata and retains runtime validation as explicit residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
  response_boundary=generated_read_burst_last_queue_head_demux
  completion=generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
  validation=report_only
  tx=r0,r1,r2
  arlen_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q
  expected=
  counters=
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

At the time of this audit, changing only that sample's `burst-length` clause
to `(validation runtime-assertion)` failed closed with the `.200` diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read mixed auto-ID plus
queue-head burst_length.validation runtime-assertion remains separately owned
in this slice; use validation report-only for the published mixed burst-length
boundary
```

Adjacent shipped runtime-validation samples prove the lower runtime substrate:

```text
ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  validation=runtime_assertion
  beat_count_validation_generated_behavior=true
  beat_count_match_source=response_demux_matched_read_beat
  tx=r0,r1
  expected=axi0_r0_expected_beats_q,axi0_r1_expected_beats_q
  counters=axi0_r0_read_beat_count_q,axi0_r1_read_beat_count_q
  assertions=8
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif
  validation=runtime_assertion
  beat_count_validation_generated_behavior=true
  beat_count_match_source=response_demux_matched_read_beat
  tx=r0,r1,r2,r3,r4
  expected=5 signals
  counters=5 signals
  assertions=20
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

## Code Findings

`_read_data_response_demux_transaction_coverage` already has a mixed
`generated_demux_and_queue_head_demux` admission branch for the exact `.200`
shape:

- response scope is read `burst_last`;
- coverage is one auto-ID read transaction plus one depth-2 concrete same-ID
  read queue-head group;
- covered transaction names are `r0`, `r1`, and `r2`;
- completion validity is
  `generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`.

`.200` added the deliberate local runtime guard inside that mixed branch:

```text
read_data.read mixed auto-ID plus queue-head burst_length.validation
runtime-assertion remains separately owned
```

Below that guard, the runtime-validation machinery is already transaction-list
driven:

- `_normalize_read_data_burst_length` accepts existing
  `validation runtime-assertion` syntax;
- `_normalize_read_data_read` assigns raw-`ARLEN` storage, expected-beat
  storage, read-beat counters, beat-count init rules, increment rules, and
  assertion names per covered transaction;
- `_read_data_beat_count_storage_lines`,
  `_read_data_beat_count_rule_lines`, and
  `_read_data_beat_count_assertion_specs` emit the runtime state, rules, and
  four beat-count/`RLAST` assertions per transaction;
- `_read_data_generated_artifacts` and `_report_read_data` project generated
  expected-beat storage, counters, rules, assertions, match source, and residue
  removal from the same normalized transaction list.

The remaining blocker at the time was therefore local admission/publication
for one mixed shape, not parser syntax, schedule normalization, generated
artifact projection, report projection, semantic JSON, or HDL lowering.

## Selected `.202` Boundary

`.202` should implement only the runtime-validation sibling of `.200`:

- read family only;
- one same-family auto-ID read transaction plus one depth-2 concrete same-ID
  read issue-order queue group;
- read `response-demux` with `response-scope burst-last`,
  one-bit `axi0_rlast`, and generated transaction completions;
- scalar last-beat `RDATA`/`RRESP` read-data capture for `r0`, `r1`, and
  `r2`;
- request-captured `burst-length` metadata using `axi0_arlen` width 8,
  `encoding axlen-plus-one`, `max-beats 16`, and
  `validation runtime-assertion`;
- a public support-accounted PPIF sample, expected name:
  `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif`;
- focused generator and PPIF/CLI expectations for generated `axi0_arlen`,
  `r0/r1/r2` raw-`ARLEN` storage, expected-beat storage,
  read-beat counters, beat-count init/increment rules, 12 beat-count/`RLAST`
  assertions, `beat_count_match_source: response_demux_matched_read_beat`,
  `burst_length_validation: runtime_assertion`,
  removal of `generated_beat_count_validation` residue, support accounting,
  semantic JSON, and HDL verification;
- support/residue/capability prose updates so mixed runtime validation is
  supported and only mixed multi-beat output banks remain deferred for this
  branch.

## Non-Goals

- Do not implement mixed multi-beat output-bank behavior.
- Do not add single-beat burst-length behavior.
- Do not add new PPIF syntax.
- Do not widen group-local simultaneous enqueue behavior.
- Do not add write-family read-data behavior.
- Do not add packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output generation, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

The `.202` implementation should run focused Perl syntax checks, direct
strict-check/schedule/semantic/HDL probes for the new public runtime sample,
preservation probes for the `.200` report-only mixed sample and adjacent
runtime-validation samples, focused generator and PPIF/CLI expectations,
support-accounting corpus gates, Knowledge Map, mdBook, docs path audit,
memory architecture, diff hygiene, README numbering, and stale/positive
frontier scans.

## Rollback Boundary

Rollback for `.201` is limited to this audit document, task-tree frontier
movement, README, roadmap, mdBook, Memory, and Knowledge Map/fact-card
updates. No parser, generator, public sample, support-accounting catalog,
generated artifact, test, validation, or HDL behavior changes in this audit
slice.
