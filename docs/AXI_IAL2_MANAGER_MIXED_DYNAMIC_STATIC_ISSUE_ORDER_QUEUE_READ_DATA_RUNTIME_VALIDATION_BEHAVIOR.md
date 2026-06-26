# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Runtime-Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.518`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.518` implements runtime
beat-count/`RLAST` validation over generated mixed dynamic/static read
burst-last same-ID `issue-order-queue` scalar last-beat read-data with
request-captured raw `ARLEN`.

The supported shape is deliberately narrow:

- exactly one dynamic read transaction and one concrete static read
  transaction;
- exactly one generated mixed dynamic/static same-ID queue with depth 2;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` is generated with `response-scope burst-last`,
  one-bit `last-signal`, and transaction completion source
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read` covers the dynamic transaction followed by the static
  transaction exactly once; and
- `burst-length` uses source `arlen`, width-8 signal, `axlen-plus-one`
  encoding, request capture, and `validation runtime-assertion`.

Multi-beat output banks over this mixed queue, broader mixed queue cardinality,
scoreboards, direct backend behavior, backend-language variants,
verification-output generation, external converter dependencies, and VHDL
remain future exact-owner work.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif
```

It is registered as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion_pipeline_cli
```

## Contract

The PPIF source is the runtime-validation sibling of the `.516` report-only
raw-`ARLEN` sample. It changes only the `burst-length.validation` mode:

```lisp
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The response-demux remains queue-owned:

```text
mode: bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report keeps scalar last-beat payload capture and adds runtime
beat-count metadata:

```text
mode: bounded_last_beat_read_data_contract
completion_validity: generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
burst_length_source: arlen_signal
burst_length_validation: runtime_assertion
beat_count_validation_generated_behavior: true
expected_beat_count_encoding: arlen_plus_one
beat_count_match_source: response_demux_matched_read_beat
generated_burst_length_inputs: axi0_arlen
generated_burst_length_storage: axi0_r0_arlen_q, axi0_r1_arlen_q
generated_expected_beat_count_storage: axi0_r0_expected_beats_q, axi0_r1_expected_beats_q
generated_read_beat_count_storage: axi0_r0_read_beat_count_q, axi0_r1_read_beat_count_q
generated_read_beat_count_rules: axi0_r0_beat_count_init, axi0_r0_read_beat_count, axi0_r1_beat_count_init, axi0_r1_read_beat_count
residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation
```

## Generated Rules

Each request captures raw `ARLEN`, initializes expected beats to `ARLEN + 1`,
and clears the transaction beat counter:

```lisp
(rule axi0_r0_beat_count_init axi0_r0_request
  (axi0_r0_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r0_read_beat_count_q 0))

(rule axi0_r1_beat_count_init axi0_r1_request
  (axi0_r1_expected_beats_q (+ axi0_arlen[4:0] 5'd1))
  (axi0_r1_read_beat_count_q 0))
```

Each raw matched read beat increments the covered transaction counter. The
match predicate is generated from the mixed dynamic/static queue state and the
incoming `RID`; scalar last-beat `RDATA`/`RRESP` capture remains guarded by the
queue-owned last-beat completion pulse.

For each covered transaction, FSMGen emits four runtime assertions:

```text
axi0_<tx>_arlen_within_max
axi0_<tx>_read_beat_before_expected_count
axi0_<tx>_rlast_on_expected_beat
axi0_<tx>_expected_final_beat_has_rlast
```

The public two-transaction sample therefore generates eight beat-count/`RLAST`
assertions.

## Validation

Validation passed for:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/248-regression-corpus-accounting.t
perl -c t/297-capability-manifest.t
env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
env -u PERL5LIB prove -Iperl t/297-capability-manifest.t
```

The guarded schedule JSON attempt for the new sample stopped before a runtime
result because host memory was already above the 88% RAM-guard cutoff. No
unguarded retry or cutoff raise was used.

## Rollback

Rollback is localized to the `.518` slice:

- remove the runtime PPIF sample and support-accounting entry;
- change the mixed dynamic/static issue-order queue read-data burst-length
  admission back to report-only only;
- remove the focused parser/generator/support-accounting tests for the runtime
  sample;
- revert the report/static-rule and public-surface prose updates for selected
  mixed queue runtime validation; and
- remove this behavior record and its Knowledge Map fact card.

The `.514` scalar mixed queue read-data behavior, `.516` report-only raw-`ARLEN`
behavior, dynamic issue-order queue runtime behavior, and ordinary mixed
response-demux runtime behavior remain independent.
