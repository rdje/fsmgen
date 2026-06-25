# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.468`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.468` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.469`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated dynamic read
same-ID `issue-order-queue` last-beat read-data.

No new public contract-selection leaf is required. The existing
`read-data.read` `burst-length` clause already defines source `arlen`, a
width-8 signal, `axlen-plus-one` encoding, request-time capture,
`max-beats`, and `report-only` versus `runtime-assertion` validation. The
current queue read-data behavior already owns scalar last-beat `RDATA`/`RRESP`
capture for the exact two-transaction queue. The remaining gap is the local
coverage gate that still rejects `burst-length` metadata for generated dynamic
issue-order queue read-data.

This readiness audit changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Evidence Read

The audit read:

- `.467` paired scalar read-data behavior over generated dynamic read same-ID
  `issue-order-queue` completions.
- `.466` queue read-data contract selection and `.465` readiness audit.
- `.463` generated dynamic read burst-last `RID && RLAST`
  `issue-order-queue` behavior.
- `.459` generated dynamic read single-beat `RID` `issue-order-queue`
  behavior.
- Generated dynamic raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat
  behavior records.
- Multiple dynamic read-data behavior records.
- Concrete queue-head raw-`ARLEN`, runtime, and multi-beat precedents.
- Current read-data burst-length normalization, artifact generation, report,
  residue, parser/CLI/generator-test, support-accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map surfaces.

Two live probes anchored the current boundary:

- The shipped dynamic read burst-last issue-order queue read-data sample emits
  schedule JSON under the existing scalar `.467` contract.
- A temporary candidate that adds report-only `burst-length` to that sample
  fails closed at the current dynamic issue-order queue read-data coverage
  diagnostic, with no lower parser or syntax prerequisite exposed.

## Current Boundary

Generated dynamic issue-order queue read-data is currently admitted only for
scalar single-beat and scalar last-beat shapes without `burst-length`
metadata. The fail-closed diagnostic is intentionally local to
`_read_data_response_demux_transaction_coverage`.

The neighboring raw-`ARLEN` substrate is already transaction-list driven:

- `_normalize_read_data_burst_length` accepts `source arlen`, width-8
  `signal`, `axlen-plus-one`, `capture request`, `max-beats` in `1..256`, and
  `report-only` or `runtime-assertion`.
- `_normalize_read_data_read` attaches per-transaction raw-`ARLEN` storage and
  capture metadata once a last-beat or multi-beat read-data shape admits
  `burst-length`.
- `_read_data_burst_length_capture_rule_lines` emits request-guarded raw
  `ARLEN` capture for each covered transaction.
- `_read_data_generated_artifacts` and `_report_read_data` already report
  generated burst-length inputs, storage, and rules.

That substrate is sufficient for a direct report-only queue implementation
once the dynamic issue-order queue coverage branch admits the exact
last-beat-plus-burst-length shape.

## Selected `.469` Implementation Boundary

`.469` should implement only:

- exactly two all-dynamic read transactions;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read` with `response-scope burst-last`,
  one-bit `last-signal`, generated transaction completion, and
  `transaction_completion_source`
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, and complete scalar transaction bindings for `r0` and
  `r1`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation report-only`;
- generated `axi0_arlen` input, `axi0_r0_arlen_q` and `axi0_r1_arlen_q`
  storage, and request-guarded `axi0_r0_burst_length_capture` and
  `axi0_r1_burst_length_capture` rules; and
- scalar last-beat `RDATA`/`RRESP` capture that remains guarded by the
  existing queue-owned last-beat completion pulses.

The support-accounted public sample selected for `.469` is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
```

The selected support-accounting identity and coverage bucket are:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_pipeline_cli
```

## Report Contract

The queue-owned response-demux report remains:

```text
bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
generated_dynamic_issue_order_queue_demux_last_beat
```

The read-data report remains a last-beat scalar read-data contract, with raw
`ARLEN` report-only metadata added:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    interleaving_policy: last_beat_by_rid
    burst_length_source: arlen_signal
    burst_length_generated_behavior: true
    burst_length_validation: report_only
    generated_burst_length_inputs: [axi0_arlen]
    generated_burst_length_storage: [axi0_r0_arlen_q, axi0_r1_arlen_q]
    generated_burst_length_rules: [axi0_r0_burst_length_capture, axi0_r1_burst_length_capture]
```

The `.467` no-`burst-length` queue read-data sample must continue to report
`burst_length_source: rlast_only` and `burst_length_validation:
not_generated`.

## Required Diagnostics

`.469` must fail closed when:

- queue read-data with `burst-length` is attempted on single-beat capture;
- the response-demux source is not
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- the queue transaction list is not exactly the two all-dynamic queue
  transactions;
- `read-data.read` omits `r0` or `r1`, duplicates a binding, or names a
  transaction outside the generated dynamic issue-order queue;
- `burst-length` uses a source other than `arlen`, non-width-8 signal,
  non-`axlen-plus-one` encoding, non-request capture, invalid `max-beats`, or
  `validation runtime-assertion`; or
- the request attempts runtime beat-count/`RLAST` validation, multi-beat
  output banks, queue recapture widening, broader queue cardinality, mixed
  dynamic/static queues, scoreboards, direct backend behavior,
  backend-language variants, or VHDL.

## Non-Goals

`.468` changes no behavior. `.469` must also leave these future exact owners
out of scope:

- runtime beat-count/`RLAST` validation over generated dynamic issue-order
  queues;
- multi-beat output banks over generated dynamic issue-order queues;
- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.468`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The readiness probes described above are boundary evidence only; no behavior
validation is claimed for `.468`.

`.469` should add focused syntax, schedule JSON, strict check JSON, semantic
JSON, default HDL or guarded HDL reachability, focused dynamic suite, and
support-accounting validation for the new public sample.

## Rollback

Rollback removes this audit document and fact card, reverts the `.468` task
tree/memory/README/roadmap/mdBook updates, and returns the active frontier to
`.468`. No code or runtime behavior rollback is needed.
