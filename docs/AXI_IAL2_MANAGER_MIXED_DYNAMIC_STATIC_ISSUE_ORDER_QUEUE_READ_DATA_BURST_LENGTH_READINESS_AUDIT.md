# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.515`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.515` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.516`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar read-data.

No separate public contract-selection leaf is required. Existing
`read-data.read` `burst-length` syntax already describes source `arlen`,
width-8 signal metadata, `axlen-plus-one` encoding, request capture,
`max-beats`, and `validation report-only`. The generated dynamic queue
raw-`ARLEN` behavior and ordinary mixed dynamic/static response-demux
raw-`ARLEN` behavior already prove the two halves of the contract. The
remaining blocker is local to read-data transaction coverage for the generated
mixed queue completion source with `burst_length` metadata present.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, schedule/check/semantic
JSON, test, HDL/runtime behavior, backend behavior, external converter
dependency, verification-output, or VHDL behavior.

## Evidence Read

The audit read:

- `.514` mixed dynamic/static issue-order queue scalar read-data behavior.
- `.513` mixed dynamic/static issue-order queue read-data readiness audit.
- `.509` generated mixed dynamic/static read burst-last `RID && RLAST`
  same-ID `issue-order-queue` behavior.
- `.467` and `.469` generated dynamic issue-order queue scalar and
  report-only raw-`ARLEN` read-data behavior.
- `.284` and `.287` generated mixed dynamic/static response-demux scalar and
  report-only raw-`ARLEN` read-data behavior.
- Current read-data coverage, burst-length normalization/report/artifact
  helpers, parser/CLI tests, generator tests, support-accounting catalog,
  README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map surfaces.

## Current Boundary

The `.514` mixed dynamic/static issue-order queue branch in
`_read_data_response_demux_transaction_coverage` admits only:

- `generated_mixed_dynamic_static_issue_order_queue_demux` with
  `capture_scope single-beat` and no `burst_length`; and
- `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat` with
  `capture_scope last-beat` and no `burst_length`.

The branch deliberately requires:

```text
!$args{has_burst_length}
```

The dynamic issue-order queue branch immediately above it already admits
last-beat queue read-data with `burst_length_validation report_only` or
`runtime_assertion`. The ordinary mixed dynamic/static read-data branch already
admits report-only raw-`ARLEN` over exactly one dynamic read transaction plus
one concrete static read transaction.

## Temporary Candidate Probe

A temporary PPIF candidate under `/private/tmp` added existing report-only
raw-`ARLEN` `burst-length` metadata to the `.514` mixed burst-last queue
read-data sample:

```text
/private/tmp/ial2-mixed-queue-read-data-burst-length.ppif
```

The guarded probe stayed below the 88% host-memory cutoff and failed closed at
the current local mixed queue branch diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read mixed dynamic/static issue-order queue coverage requires generated mixed dynamic/static read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, or generated mixed dynamic/static read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata, over exactly one dynamic read transaction plus one concrete static read transaction in one depth-2 generated mixed queue in this slice
```

The candidate parsed far enough to reach read-data coverage. No parser syntax,
public source-shape, PPIF adapter, IAL1, IAL0, SystemVerilog, backend,
external converter, or VHDL prerequisite was exposed.

## Selected `.516` Implementation Boundary

`.516` should implement only report-only raw-`ARLEN` burst-length capture over
generated mixed dynamic/static read burst-last same-ID issue-order queue
scalar read-data:

- exactly one dynamic read transaction and one concrete static read
  transaction;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read`;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`;
- transaction completion source
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- one depth-2 generated mixed dynamic/static read issue-order queue;
- `read-data.read.capture-scope last-beat`;
- `read-data.read.completion-source response-demux`;
- complete scalar `RDATA`/`RRESP` transaction bindings;
- `burst-length` source `arlen`, width 8, `axlen-plus-one`, request capture,
  `max-beats 1..256`, and `validation report-only`.

The selected public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
```

The selected support-accounting identity and coverage bucket should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_pipeline_cli
```

## Expected Report Contract

The response-demux report should remain queue-owned:

```text
bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report should keep the existing last-beat scalar mode and the
`.514` queue-specific completion-validity name:

```text
bounded_last_beat_read_data_contract
generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

The report should add the existing report-only raw-`ARLEN` metadata:

```text
burst_length_source: arlen_signal
burst_length_validation: report_only
generated_burst_length_inputs: axi0_arlen
generated_burst_length_storage: axi0_r0_arlen_q, axi0_r1_arlen_q
generated_burst_length_rules: axi0_r0_burst_length_capture, axi0_r1_burst_length_capture
```

Scalar last-beat `RDATA`/`RRESP` capture must stay guarded only by the
generated mixed queue completion pulses. Raw-`ARLEN` capture must use the
request events and must not affect response matching or queue dequeue logic.

## Diagnostics

`.516` must fail closed when:

- `burst-length` is present on the single-beat mixed queue read-data shape;
- `capture-scope` is not `last-beat`;
- `response-demux.read.response-scope` is not `burst-last`;
- `transaction_completion_source` is not
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- the generated mixed queue is not exactly one dynamic read plus one concrete
  static read transaction in one depth-2 queue;
- `burst-length` is not source `arlen`, width 8, `axlen-plus-one`, request
  capture, valid `max-beats`, and `validation report-only`; or
- the source attempts runtime beat-count/`RLAST` validation, multi-beat output
  banks, broader mixed queue cardinality, scoreboards, direct backend
  behavior, backend-language variants, verification-output generation,
  external converter dependency selection, or VHDL.

## Non-Goals

`.515` changes no behavior. `.516` should also leave these future exact
owners out of scope:

- runtime beat-count/`RLAST` validation over generated mixed dynamic/static
  issue-order queues;
- multi-beat output banks over generated mixed dynamic/static issue-order
  queues;
- raw-`ARLEN` over single-beat read-data;
- broader mixed queue cardinality;
- scoreboards;
- direct backend behavior;
- backend-language variants;
- verification-code generation;
- external converter dependency selection such as `sv2v`; and
- VHDL.

## Validation

This readiness audit ran the guarded temporary candidate probe above and
closed with documentation and continuity gates:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No parser, generator, PPIF sample, support-accounting, generated-artifact,
schedule/check/semantic JSON, test, HDL/runtime behavior, backend behavior,
external converter dependency, verification-output, or VHDL behavior changed.
