# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Burst-Length Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.469`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.469` implements report-only raw-`ARLEN`
burst-length capture over generated dynamic read same-ID
`issue-order-queue` scalar last-beat read-data.

The supported shape is deliberately narrow:

- exactly two read transactions;
- both read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` is generated with `response-scope burst-last`,
  one-bit `last-signal`, and transaction completion source
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read` covers exactly the two generated dynamic queue
  transactions once each; and
- `burst-length` uses source `arlen`, width-8 signal, `axlen-plus-one`
  encoding, request capture, and `validation report-only`.

Runtime beat-count/`RLAST` validation, multi-beat output banks, queue
recapture widening, broader queue cardinality, mixed dynamic/static queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain future exact-owner work.

## Public Sample

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
```

It is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_pipeline_cli
```

## Contract

The PPIF source extends the `.467` scalar last-beat queue read-data sample with
only the existing `burst-length` metadata:

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
      (validation report-only))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The response-demux remains queue-owned:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
```

The read-data report adds raw-`ARLEN` report-only capture to the existing
last-beat read-data mode:

```text
mode: bounded_last_beat_read_data_contract
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
burst_length_source: arlen_signal
burst_length_validation: report_only
generated_burst_length_inputs: axi0_arlen
generated_burst_length_storage: axi0_r0_arlen_q, axi0_r1_arlen_q
generated_burst_length_rules: axi0_r0_burst_length_capture, axi0_r1_burst_length_capture
residue: generated_beat_count_validation, multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation
```

## Generated Rules

The generated IAL1 keeps scalar last-beat payload capture guarded by the
queue-owned completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_last_rdata axi0_rdata)
  (axi0_r1_last_rresp axi0_rresp))
```

The new behavior adds request-time raw-`ARLEN` capture for each transaction:

```lisp
(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))

(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

The lowered scheduled `.fsm` preserves the same assignments through explicit
`<-` rule actions.

## Validation

Guarded validation passed for:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif
scripts/run_with_ram_guard.sh -- perl -Iperl <reduced parser/report/ISF/FSM probe>
prove -Iperl t/248-regression-corpus-accounting.t
```

The reduced guarded probe checked report metadata, generated `axi0_arlen`
input, `axi0_r0_arlen_q`/`axi0_r1_arlen_q` storage,
`axi0_r0_burst_length_capture`/`axi0_r1_burst_length_capture` rules, and the
scheduled `.fsm` raw-`ARLEN` assignment.

Guarded strict check JSON, semantic JSON, full filtered `t/1438`, and
HDL-lowering attempts were stopped by RAM guard host/RSS limits or reviewer
risk limits in the current memory window. They are not claimed as passed; no
unguarded retry was run.

## Rollback

Rollback is localized to the `.469` slice:

- remove the PPIF sample and support-accounting entry;
- remove the dynamic issue-order queue read-data burst-length admission from
  `_read_data_response_demux_transaction_coverage`;
- remove the focused parser/dynamic/support-accounting tests for the new
  sample;
- revert the report/static-rule prose updates for queue-backed report-only
  raw-`ARLEN`; and
- remove this behavior record and its Knowledge Map fact card.

The `.467` scalar queue read-data behavior and ordinary generated dynamic
raw-`ARLEN` behavior remain independent.
