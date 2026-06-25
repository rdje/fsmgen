# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.472`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.472` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.473`, direct bounded implementation of
multi-beat read-data output banks over generated dynamic read same-ID
`issue-order-queue` runtime-validation read-data.

No new public contract-selection leaf is required. The existing
`read-data.read` multi-beat syntax already defines `capture-scope
multi-beat`, `status-policy per-beat`, `status-aggregation worst-observed`,
`interleaving multi-beat-by-rid`, runtime-assertion `burst-length`, and
complete per-transaction output-bank bindings. The `.471` queue-backed
runtime-validation sibling proves raw `ARLEN`, expected-beat storage,
read-beat counters, matched queue read-beat increments, and
beat-count/`RLAST` assertions for the exact two-transaction queue. The
remaining blocker is the local dynamic issue-order queue read-data coverage
gate, which still admits only scalar single-beat, scalar last-beat, and
scalar last-beat report-only/runtime raw-`ARLEN` queue shapes.

This readiness audit changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Evidence Read

The audit read:

- `.471` runtime beat-count/`RLAST` validation behavior over generated dynamic
  read same-ID `issue-order-queue` raw-`ARLEN` read-data.
- `.469` report-only raw-`ARLEN` behavior and `.467` scalar queue read-data
  behavior.
- Generated dynamic multi-beat output-bank behavior for ordinary all-dynamic
  read response-demux paths.
- Multiple-dynamic, mixed dynamic/static, concrete queue-head, and depth-3
  queue-head multi-beat/runtime precedents.
- Current read-data multi-beat normalization, artifact generation, report
  projection, residue movement, static-rule prose, parser/CLI test helpers,
  support accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and
  Knowledge Map surfaces.

A guarded temporary `/tmp` candidate changed only the `.471` queue runtime
sample's read-data shape to `capture-scope multi-beat`, `status-policy
per-beat`, `status-aggregation worst-observed`, `interleaving
multi-beat-by-rid`, and complete `r0`/`r1` output-bank bindings. It failed
closed at the expected local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic issue-order queue coverage requires generated dynamic read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata, or generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata in this slice
```

The failure occurred before generated multi-beat output-bank normalization or
artifact projection. It does not expose a parser, PPIF syntax, support
accounting, IAL1, IAL0, SystemVerilog, direct backend, backend-language, or
VHDL prerequisite.

## Current Boundary

The dynamic issue-order queue read-data coverage branch currently supports:

```text
capture_scope: single-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux
response_scope: single_beat
burst_length: absent
```

and:

```text
capture_scope: last-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
response_scope: burst_last
burst_length_validation: absent, report_only, or runtime_assertion
```

It does not include a `multi-beat` supported boundary for
`generated_dynamic_issue_order_queue_demux_last_beat`.

The lower multi-beat substrate is already transaction-list driven:

- `_normalize_read_data_read` accepts `capture-scope multi-beat`,
  `status-policy per-beat`, `status-aggregation worst-observed`,
  `interleaving multi-beat-by-rid`, runtime-assertion `burst-length`, and
  per-transaction output-bank bindings.
- The same normalizer creates generated data/status lanes, valid-mask
  outputs, length outputs, scalar aggregate outputs, raw-`ARLEN` storage,
  expected-beat storage, read-beat counters, beat-count rules/assertions,
  output-init rules, lane-capture rules, and aggregate-update rules for every
  covered transaction.
- `_read_data_matched_read_beat_expr` uses the raw accepted response beat plus
  the response-demux transaction match. For dynamic issue-order queues that
  match expression comes from the queue-selected raw `RID` beat, not the
  final `RLAST` completion pulse, which is the right source for per-lane
  capture and beat counting.
- `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`, and
  `_report_read_data` already iterate over the normalized transaction list.
- `_read_data_covers_multi_beat_by_rid_interleaving` can already recognize
  the generated dynamic issue-order queue family through the same-id ordering
  response-demux coverage path once the multi-beat read-data object is
  admitted.

## Selected `.473` Implementation Boundary

`.473` should implement only:

- exactly two all-dynamic read transactions;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read` with `response-scope burst-last`,
  one-bit `last-signal`, generated transaction completion, and
  `transaction_completion_source`
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation
  worst-observed`, `interleaving multi-beat-by-rid`, and runtime-assertion
  `burst-length` metadata;
- complete exactly-once output-bank bindings for `r0` and `r1`:
  `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`;
- per-transaction output-bank initialization, per-lane `RDATA`/`RRESP`
  capture, valid-mask and length updates, scalar `RRESP` aggregation, raw
  `ARLEN` capture, expected-beat storage, beat counters, beat-count rules,
  and beat-count/`RLAST` assertions; and
- report/residue movement for the selected queue multi-beat shape while
  preserving `.467`, `.469`, and `.471`.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

The selected support-accounting identity and coverage bucket are:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat_pipeline_cli
```

## Expected Report Contract

The read-data report should move to the bounded multi-beat contract:

```yaml
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
    beat_match_source: response_demux_matched_read_beat
    beat_count_match_source: response_demux_matched_read_beat
    output_shape: per_beat_output_bank
    valid_output: per_transaction_valid_mask
    length_output: per_transaction_beat_count
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: true
    multi_beat_reassembly_generated_behavior: true
    burst_length_source: arlen_signal
    burst_length_validation: runtime_assertion
    generated_multi_beat_valid_outputs: [axi0_r0_beat_valid, axi0_r1_beat_valid]
    generated_multi_beat_length_outputs: [axi0_r0_read_beats, axi0_r1_read_beats]
```

For the default `max-beats 16` sample, `.473` should emit 32 `RDATA` lane
outputs, 32 `RRESP` lane outputs, two valid-mask outputs, two length outputs,
two scalar aggregate status outputs, two output-init rules, 32 lane-capture
rules, two scalar aggregate update rules, raw-`ARLEN` storage/rules,
expected-beat storage, read-beat counter storage/rules, and eight total
beat-count/`RLAST` assertions.

## Diagnostics

`.473` must fail closed when:

- the response-demux source is not
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- the response scope is not `burst-last` or the one-bit `last-signal` is
  absent;
- the same-id policy is not dynamic `issue-order-queue`;
- the queue transaction list is not exactly the two all-dynamic queue
  transactions in issue order;
- `read-data.read` omits `r0` or `r1`, duplicates a binding, names an extra
  transaction, or provides scalar last-beat output fields instead of
  multi-beat output-bank fields;
- `capture-scope multi-beat` omits runtime-assertion `burst-length`,
  `status-policy per-beat`, or `interleaving multi-beat-by-rid`; or
- the request attempts queue recapture widening, broader queue cardinality,
  mixed dynamic/static queues, scoreboards, direct backend behavior,
  backend-language variants, or VHDL.

## Non-Goals

`.472` changes no behavior. `.473` should also leave these future exact
owners out of scope:

- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.472`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.473` should add focused syntax checks, schedule JSON, strict check JSON,
semantic JSON where memory allows, focused parser/dynamic/support-accounting
tests, and guarded HDL reachability for the new queue multi-beat sample.

## Rollback

Rollback removes this audit document and fact card, reverts the `.472` task
tree/memory/README/roadmap/mdBook updates, and returns the active frontier to
`.472`. No code or runtime behavior rollback is needed.
