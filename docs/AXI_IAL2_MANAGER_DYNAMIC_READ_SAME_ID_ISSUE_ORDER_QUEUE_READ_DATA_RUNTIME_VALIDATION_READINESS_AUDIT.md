# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Runtime Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.470`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.470` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.471`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated dynamic read same-ID
`issue-order-queue` scalar last-beat read-data with raw-`ARLEN` capture.

No new public contract-selection leaf is required. The existing
`read-data.read` `burst-length` clause already supports
`(validation runtime-assertion)` for last-beat read-data. The `.469`
queue-backed report-only sibling proves the queue path now owns generated
`axi0_arlen`, per-transaction raw-`ARLEN` storage, and request-capture rules.
The remaining blocker is the local dynamic issue-order queue read-data
coverage gate, which still admits only the no-`burst-length` queue shapes and
the report-only raw-`ARLEN` last-beat shape.

This readiness audit changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Evidence Read

The audit read:

- `.469` report-only raw-`ARLEN` behavior over generated dynamic read same-ID
  `issue-order-queue` last-beat read-data.
- `.468` raw-`ARLEN` readiness audit and `.467` scalar queue read-data
  behavior.
- Generated dynamic runtime validation behavior for ordinary all-dynamic read
  response-demux paths.
- Multiple-dynamic, mixed dynamic/static, concrete queue-head, and depth-3
  queue-head runtime-validation precedents.
- Current read-data burst-length normalization, beat-count storage/rule/
  assertion generation, report projection, residue movement, parser/CLI test
  helpers, support accounting, README, ROADMAP_V2, mdBook, Memory, task tree,
  and Knowledge Map surfaces.

No heavyweight runtime candidate was launched during this audit because the
host was already under unrelated high memory pressure. The code boundary is
nevertheless local: `_read_data_response_demux_transaction_coverage` permits
the generated dynamic issue-order queue last-beat raw-`ARLEN` shape only when
`burst_length_validation` is `report_only`.

## Current Boundary

The `.469` queue branch currently allows:

```text
capture_scope: last-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
response_scope: burst_last
burst_length_validation: report_only
```

The same branch rejects `validation runtime-assertion` before the shared
runtime-validation artifact path can run.

The shared runtime-validation substrate is already transaction-list driven:

- `_normalize_read_data_read` attaches expected-beat storage, beat-count
  storage, beat-count init/increment rules, and assertion names when
  `burst_length_validation` is `runtime_assertion`.
- `_read_data_beat_count_storage_lines`,
  `_read_data_beat_count_rule_lines`, and
  `_read_data_beat_count_assertion_transaction_lines` emit the generated IAL1
  storage, rules, and assertions for every covered read-data transaction.
- `_report_read_data` reports
  `beat_count_validation_generated_behavior`,
  `expected_beat_count_encoding`, `beat_count_match_source`,
  generated beat-count storage/rules/assertions, and removes
  `generated_beat_count_validation` residue for runtime-validation shapes.
- Existing runtime-validation report helpers already accept arbitrary covered
  transaction lists and completion-validity names.

That substrate is sufficient for the two-transaction dynamic queue once the
local queue coverage gate admits `runtime_assertion`.

## Selected `.471` Implementation Boundary

`.471` should implement only:

- exactly two all-dynamic read transactions;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read` with `response-scope burst-last`,
  one-bit `last-signal`, generated transaction completion, and
  `transaction_completion_source`
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, complete scalar transaction bindings for `r0` and `r1`,
  and `burst-length (validation runtime-assertion)`;
- generated `axi0_arlen` input, raw-`ARLEN` storage/capture rules,
  expected-beat storage, beat-count storage, beat-count init/increment rules,
  and beat-count/`RLAST` assertions for `r0` and `r1`; and
- scalar last-beat `RDATA`/`RRESP` capture that remains guarded by the
  existing queue-owned last-beat completion pulses.

The selected public sample for `.471` is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

The selected support-accounting identity and coverage bucket are:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

## Report Contract

The read-data report should remain a last-beat scalar contract and add
runtime-validation metadata:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
    burst_length_source: arlen_signal
    burst_length_validation: runtime_assertion
    burst_length_generated_behavior: true
    beat_count_validation_generated_behavior: true
    expected_beat_count_encoding: arlen_plus_one
    beat_count_match_source: response_demux_matched_read_beat
    generated_burst_length_inputs: [axi0_arlen]
    generated_burst_length_storage: [axi0_r0_arlen_q, axi0_r1_arlen_q]
    generated_burst_length_rules: [axi0_r0_burst_length_capture, axi0_r1_burst_length_capture]
    generated_expected_beat_count_storage: [axi0_r0_expected_beats_q, axi0_r1_expected_beats_q]
    generated_beat_count_storage: [axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q]
```

The `.469` report-only sample must continue to omit generated beat-count
storage/rules/assertions and keep `generated_beat_count_validation` residue.

## Non-Goals

`.470` changes no behavior. `.471` should also leave these future exact
owners out of scope:

- multi-beat output banks over generated dynamic issue-order queues;
- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.470`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.471` should add focused syntax checks, schedule JSON, strict check JSON,
semantic JSON where memory allows, focused parser/dynamic/support-accounting
tests, and guarded HDL reachability for the new runtime-validation sample.

## Rollback

Rollback removes this audit document and fact card, reverts the `.470` task
tree/memory/README/roadmap/mdBook updates, and returns the active frontier to
`.470`. No code or runtime behavior rollback is needed.
