# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Runtime Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.471`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.471` implements runtime
beat-count/`RLAST` validation over generated dynamic read same-ID
`issue-order-queue` scalar last-beat read-data with raw-`ARLEN` capture.

The supported shape remains deliberately narrow:

- exactly two read transactions;
- both read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` is generated with `response-scope burst-last`,
  one-bit `last-signal`, and transaction completion source
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read` covers exactly the two generated dynamic queue transactions
  once each; and
- `burst-length` uses source `arlen`, width-8 signal, `axlen-plus-one`
  encoding, request capture, and `validation runtime-assertion`.

The `.469` report-only sample remains supported. Multi-beat output banks, queue
recapture widening, broader queue cardinality, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact-owner work.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

It is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

## Contract

The PPIF source extends the `.469` report-only raw-`ARLEN` sample by changing
only the validation mode:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

The response-demux remains queue-owned:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

## Generated Runtime Artifacts

The read-data report adds runtime validation to the `.469` raw-`ARLEN` capture:

```text
mode: bounded_last_beat_read_data_contract
burst_length_validation: runtime_assertion
beat_count_validation_generated_behavior: true
expected_beat_count_encoding: arlen_plus_one
beat_count_match_source: response_demux_matched_read_beat
beat_count_width: 5
generated_expected_beat_count_storage: axi0_r0_expected_beats_q, axi0_r1_expected_beats_q
generated_beat_count_storage: axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q
generated_beat_count_rules: axi0_r0_beat_count_init, axi0_r0_read_beat_count, axi0_r1_beat_count_init, axi0_r1_read_beat_count
generated_beat_count_assertions: axi0_r0_arlen_within_max, axi0_r0_read_beat_before_expected_count, axi0_r0_rlast_on_expected_beat, axi0_r0_expected_final_beat_has_rlast, axi0_r1_arlen_within_max, axi0_r1_read_beat_before_expected_count, axi0_r1_rlast_on_expected_beat, axi0_r1_expected_final_beat_has_rlast
residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation
```

The generated IAL1 initializes expected beats and the read-beat counter on each
transaction request:

```lisp
(rule axi0_r1_beat_count_init axi0_r1_request
  (axi0_r1_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r1_read_beat_count_q 0))
```

It increments the counter on raw matched queue read beats while not also
accepting a new request for the same transaction:

```lisp
(rule axi0_r1_read_beat_count
  (& (& axi0_read_complete
        <selected queue-head RID match for r1>)
     (! axi0_r1_request))
  (axi0_r1_read_beat_count_q (+ axi0_r1_read_beat_count_q 5'd1)))
```

For each transaction the runtime assertion set checks `ARLEN < max_beats`,
prevents the beat counter from exceeding the expected count, requires `RLAST`
only on the expected final beat, and requires `RLAST` on that final beat.

## Validation

Validation passed for:

```text
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
```

Direct reduced adapter/report/ISF/FSM probes confirmed the new public sample
parses, reports `runtime_assertion`, emits `axi0_arlen`, per-transaction raw
`ARLEN` storage/capture, expected-beat storage, read-beat counters, init and
increment rules, and the expected beat-count/`RLAST` assertions.

The filtered `t/1438` attempt was stopped after several minutes without TAP
while CPU-active in the HDL-heavy path. Guarded strict check JSON exceeded the
4 GiB default and a 6 GiB retry RSS cutoff; semantic JSON was not claimed after
the same memory profile. No unguarded retry was run.

## Rollback

Rollback is localized to the `.471` slice:

- remove the runtime PPIF sample and support-accounting entry;
- restore the dynamic issue-order queue read-data burst-length admission to
  report-only only;
- remove focused parser/dynamic/support-accounting tests for the runtime
  sample;
- revert report/static-rule prose updates that mention queue-backed
  runtime-assertion raw-`ARLEN`; and
- remove this behavior record and its Knowledge Map fact card.

The `.469` report-only raw-`ARLEN` sample and `.467` scalar queue read-data
samples remain independent.
