# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.499`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.499` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.500`, direct bounded implementation of
multi-beat read-data output banks over generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 runtime-validation
read-data.

No new public contract-selection leaf is required. The existing
`read-data.read` multi-beat syntax already defines `capture-scope
multi-beat`, `status-policy per-beat`, `status-aggregation worst-observed`,
`interleaving multi-beat-by-rid`, runtime-assertion `burst-length`, and
complete per-transaction output-bank bindings. The `.497` queue-backed
runtime-validation sibling proves raw `ARLEN`, expected-beat storage,
read-beat counters, matched queue read-beat increments, and
beat-count/`RLAST` assertions for the exact three-transaction queue. The
remaining blocker is the local dynamic issue-order queue read-data coverage
gate, which still admits multi-beat only over the two-transaction dynamic
RLAST queue.

This readiness audit changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, external converter
dependency, direct backend behavior, backend-language variant,
verification-code output, or VHDL behavior.

## Evidence Read

The audit read:

- `.498` selector, `.497` runtime-validation behavior, `.496` readiness audit,
  `.494` raw-`ARLEN` behavior, `.491` scalar read-data behavior, and `.488`
  depth-3 RLAST queue behavior.
- `.473` two-transaction dynamic queue multi-beat behavior and `.471`
  two-transaction dynamic queue runtime-validation behavior.
- Current dynamic issue-order queue read-data coverage, multi-beat
  normalization, artifact generation, report projection, residue movement,
  parser/CLI test helpers, generator helper tests, dynamic-ID focused tests,
  support accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and
  Knowledge Map surfaces.

A RAM-guarded temporary `/tmp` candidate changed only the `.497` runtime
sample's read-data shape to `capture-scope multi-beat`, `status-policy
per-beat`, `status-aggregation worst-observed`, `interleaving
multi-beat-by-rid`, and complete `r0`/`r1`/`r2` output-bank bindings. It
failed closed at the expected local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic issue-order queue coverage requires generated dynamic read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata over two dynamic transactions or one depth-3 all-dynamic queue, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata over two dynamic transactions, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata over one depth-3 all-dynamic queue, or generated dynamic read issue-order queue burst-last response_demux with capture_scope multi-beat and runtime-assertion burst_length metadata over two dynamic transactions in this slice
```

The temporary file was removed after the probe. The failure occurred before
generated multi-beat output-bank normalization or artifact projection. It does
not expose a parser, PPIF syntax, support accounting, IAL1, IAL0,
SystemVerilog, direct backend, backend-language, external converter, or VHDL
prerequisite.

## Current Boundary

The dynamic issue-order queue read-data coverage branch currently supports:

```text
capture_scope: single-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux
response_scope: single_beat
burst_length: absent
transaction count: 2
queue depth: 2
```

and:

```text
capture_scope: last-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
response_scope: burst_last
burst_length_validation: absent, report_only, or runtime_assertion
transaction count: 2 or 3
queue depth: 2 or exactly one all-dynamic depth-3 queue
```

and:

```text
capture_scope: multi-beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
response_scope: burst_last
burst_length_validation: runtime_assertion
transaction count: 2
queue depth: 2
```

It does not include the selected depth-3 `multi-beat` supported boundary.

The lower multi-beat substrate is already transaction-list driven:

- `_normalize_read_data_read` accepts multi-beat output-bank bindings and
  creates generated lane, valid-mask, length, scalar aggregate, raw-`ARLEN`,
  expected-beat, beat-count, rule, and assertion names for each normalized
  transaction.
- `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`, and
  `_report_read_data` iterate over `read_data.read.transactions`.
- `_read_data_capture_rule_lines` uses
  `_read_data_matched_read_beat_expr` and the response-demux state for each
  transaction, so lane capture follows matched raw queue read beats rather
  than waiting for the final `RID && RLAST` completion pulse.
- `_read_data_covers_multi_beat_by_rid_interleaving` can already recognize the
  generated dynamic issue-order queue family through same-ID ordering
  response-demux coverage once the multi-beat read-data object is admitted.
- Existing parser/generator focused helpers accept a transaction list when
  asserting multi-beat report fields, so `r0`/`r1`/`r2` checks can reuse the
  same test vocabulary.

## Selected `.500` Implementation Boundary

`.500` should implement only:

- exactly three all-dynamic read transactions;
- `same-id-ordering.read` with `(dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read` with `response-scope burst-last`,
  one-bit `last-signal`, generated transaction completion, and
  `transaction_completion_source`
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `first_generated_scope` `read_rid_rlast_three_dynamic_transactions`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation
  worst-observed`, `interleaving multi-beat-by-rid`, and runtime-assertion
  `burst-length` metadata;
- complete exactly-once output-bank bindings for `r0`, `r1`, and `r2`:
  `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`;
- per-transaction output-bank initialization, per-lane `RDATA`/`RRESP`
  capture, valid-mask and length updates, scalar `RRESP` aggregation, raw
  `ARLEN` capture, expected-beat storage, beat counters, beat-count rules, and
  beat-count/`RLAST` assertions; and
- report/residue movement for the selected queue multi-beat shape while
  preserving `.491`, `.494`, `.497`, and the two-transaction `.467`/`.469`/
  `.471`/`.473` ladder.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
```

The selected support-accounting identity and coverage bucket are:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat_pipeline_cli
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
    generated_multi_beat_valid_outputs: [axi0_r0_beat_valid, axi0_r1_beat_valid, axi0_r2_beat_valid]
    generated_multi_beat_length_outputs: [axi0_r0_read_beats, axi0_r1_read_beats, axi0_r2_read_beats]
```

For the default `max-beats 16` sample, `.500` should emit 48 `RDATA` lane
outputs, 48 `RRESP` lane outputs, three valid-mask outputs, three length
outputs, three scalar aggregate status outputs, three output-init rules, 48
lane-capture rules, three scalar aggregate update rules, raw-`ARLEN`
storage/rules, expected-beat storage, read-beat counter storage/rules, and
twelve total beat-count/`RLAST` assertions.

## Diagnostics

If `.500` remains fail-closed, the diagnostic should explicitly mention
runtime-assertion multi-beat output-bank coverage over one depth-3 all-dynamic
queue, while preserving the existing fail-closed wording for unsupported
mixed/static queues, broader arbitrary cardinality, non-runtime multi-beat,
and non-burst-last response-demux shapes.

## Validation Scope For `.500`

The implementation owner should run focused syntax and support checks plus
RAM-guarded sample/report probes where host memory allows:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The broad focused suites and strict/semantic/HDL probes may hit existing RAM
guard caveats; no unguarded retry or host cutoff increase is selected by this
audit.

## Deferred Alternatives

`.499` explicitly defers mixed dynamic/static issue-order queues, scoreboards,
same-cycle queue widening beyond already-owned queue recapture records,
arbitrary queue cardinality, verification-code generation, direct backend
behavior, backend-language variants, external converter dependency selection,
and VHDL. FSMGen-owned generation and lowering remain the default; `sv2v`
remains an optional future audit candidate only.

## Rollback

Rollback is documentation-only for `.499`: revert this audit record, the
matching Knowledge Map fact card/map entry, task-tree advancement,
README/ROADMAP/mdBook sync, and Memory pointer. No generated HDL, runtime
artifact, parser behavior, or support-accounting rollback is required.
