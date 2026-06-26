# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Runtime-Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.517`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.517` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.518`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated mixed dynamic/static read
burst-last same-ID `issue-order-queue` scalar last-beat read-data with
raw-`ARLEN` capture.

No separate public contract-selection leaf is required. The existing
`read-data.read` `burst-length` syntax already supports `validation
runtime-assertion`, and the shared read-data generator already creates
request-time raw-`ARLEN` capture, expected-beat storage, read-beat counters,
matched-read-beat increment rules, and beat-count/`RLAST` assertion metadata
once the response-demux coverage branch admits a runtime assertion contract.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, schedule/check/semantic
JSON, test, HDL/runtime behavior, backend behavior, external converter
dependency, verification-output, or VHDL behavior.

## Evidence Read

The audit read:

- `.516` mixed dynamic/static issue-order queue report-only raw-`ARLEN`
  read-data behavior.
- `.515` mixed dynamic/static issue-order queue raw-`ARLEN` readiness audit.
- `.514` mixed dynamic/static issue-order queue scalar read-data behavior.
- `.469` and `.471` generated dynamic issue-order queue report-only
  raw-`ARLEN` and runtime-validation read-data behavior.
- `.287` and `.289` generated mixed dynamic/static response-demux report-only
  raw-`ARLEN` and runtime-validation read-data behavior.
- Current `burst_length` normalization, read-data coverage selection,
  runtime beat-count/`RLAST` generation, report artifact projection,
  parser/CLI and generator tests, support-accounting catalog, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map surfaces.

## Current Boundary

The `.516` mixed dynamic/static issue-order queue branch in
`_read_data_response_demux_transaction_coverage` now admits:

- `generated_mixed_dynamic_static_issue_order_queue_demux` with
  `capture_scope single-beat` and no `burst_length`;
- `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat` with
  `capture_scope last-beat` and no `burst_length`; and
- `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat` with
  `capture_scope last-beat` and `burst_length_validation report_only`.

The local branch still rejects `burst_length_validation runtime_assertion`.
That is the only implementation blocker found in the audit. The shared
normalization path already accepts `validation runtime-assertion`, and the
shared runtime path adds:

```text
beat_count_validation_generated_behavior: true
expected_beat_count_encoding: arlen_plus_one
beat_count_match_source: response_demux_matched_read_beat
generated_expected_beat_count_storage
generated_beat_count_storage
generated_beat_count_rules
generated_beat_count_assertions
```

for last-beat raw-`ARLEN` read-data contracts after coverage is admitted.

## Temporary Candidate Probe

A temporary candidate under `/private/tmp` changed only the `.516` public
sample's `burst-length.validation` from `report-only` to
`runtime-assertion`:

```text
/private/tmp/ial2-mixed-queue-read-data-burst-length-runtime.ppif
```

The first guarded run failed because process-tree inspection is unavailable
inside the sandbox. The approved guarded rerun stopped before any parser or
coverage diagnostic when host memory was already above the 88% cutoff:

```text
host memory 88.5% reached cutoff 88%
```

No unguarded retry or cutoff raise was used. The temporary file was removed.
The selection below is therefore based on source inspection and the existing
dynamic queue plus ordinary mixed response-demux runtime-validation precedents.

## Selected `.518` Implementation Boundary

`.518` should implement only runtime beat-count/`RLAST` validation over
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
  `max-beats 1..256`, and `validation runtime-assertion`; and
- completion validity
  `generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.

The selected public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

The selected support-accounting identity and coverage bucket should be:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

## Expected Report Contract

The response-demux report should remain queue-owned:

```text
bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report should keep the scalar last-beat mode and queue-specific
completion-validity name:

```text
bounded_last_beat_read_data_contract
generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

The report should add runtime validation metadata to the `.516` raw-`ARLEN`
capture:

```text
burst_length_source: arlen_signal
burst_length_validation: runtime_assertion
beat_count_validation_generated_behavior: true
expected_beat_count_encoding: arlen_plus_one
beat_count_match_source: response_demux_matched_read_beat
generated_expected_beat_count_storage: axi0_r0_expected_beats_q, axi0_r1_expected_beats_q
generated_beat_count_storage: axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q
generated_beat_count_rules: axi0_r0_beat_count_init, axi0_r0_read_beat_count, axi0_r1_beat_count_init, axi0_r1_read_beat_count
generated_beat_count_assertions: four assertions per covered transaction
```

Scalar last-beat `RDATA`/`RRESP` capture must stay guarded by the generated
mixed queue completion pulses. Runtime beat counting must count raw matched
read beats for the selected dynamic or static queue slot, not only final
`RLAST` completions.

## Diagnostics

`.518` must fail closed when:

- `burst-length` is present on the single-beat mixed queue read-data shape;
- `capture-scope` is not `last-beat`;
- `response-demux.read.response-scope` is not `burst-last`;
- `transaction_completion_source` is not
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- the generated mixed queue is not exactly one dynamic read plus one concrete
  static read transaction in one depth-2 queue;
- `burst-length` is not source `arlen`, width 8, `axlen-plus-one`, request
  capture, valid `max-beats`, and `validation runtime-assertion`; or
- the source attempts multi-beat output banks, broader mixed queue
  cardinality, scoreboards, direct backend behavior, backend-language variants,
  verification-output generation, external converter dependency selection, or
  VHDL.

## Non-Goals

`.517` changes no behavior. `.518` should also leave these future exact owners
out of scope:

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

This readiness audit ran the temporary candidate probe above, which stopped at
the 88% RAM guard before a diagnostic, and closed with documentation and
continuity gates:

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
