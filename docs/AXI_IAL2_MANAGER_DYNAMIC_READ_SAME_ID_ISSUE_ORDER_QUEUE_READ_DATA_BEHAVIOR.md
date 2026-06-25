# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.467`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.467` implements paired scalar read-data
routing over the generated dynamic read same-ID `issue-order-queue`
response-demux completions.

The covered public shapes are deliberately narrow:

- exactly two read transactions;
- both read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` owns generated dynamic issue-order queue completions;
- `read-data.read` uses existing scalar single-beat or scalar last-beat syntax;
- `read-data.read` covers exactly the two generated dynamic queue
  transactions once each;
- raw `ARLEN`, runtime beat-count/RLAST validation, multi-beat output banks,
  queue recapture widening, broader queue cardinality, mixed dynamic/static
  queues, scoreboards, direct backend behavior, backend-language variants, and
  VHDL remain future exact-owner work.

## Public Samples

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif
```

They are registered as strict-supported PPIF entries:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data
```

with coverage buckets:

```text
ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_pipeline_cli
```

## Single-Beat Contract

The single-beat sample extends the generated dynamic read single-beat queue
with scalar `RDATA`/`RRESP` capture:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))

(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))))
```

The response-demux remains queue-owned:

```text
mode: bounded_dynamic_read_rid_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux
```

The read-data report uses queue-specific validity:

```text
mode: bounded_single_beat_read_data_contract
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_completion_pulse
transactions: r0, r1
generated_inputs: axi0_rdata, axi0_rresp
generated_rules: axi0_r0_read_data_capture, axi0_r1_read_data_capture
residue: rlast_completion, bursts, multi_beat_read_data_reassembly
```

## Last-Beat Contract

The burst-last sample extends the generated dynamic read burst-last queue with
scalar last-beat `RDATA`/`RRESP` capture:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))

(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
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

The read-data report uses queue-specific last-beat validity:

```text
mode: bounded_last_beat_read_data_contract
completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
transactions: r0, r1
generated_inputs: axi0_rdata, axi0_rresp
generated_rules: axi0_r0_read_data_capture, axi0_r1_read_data_capture
residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation, arlen_or_beat_count_validation
```

## Generated Rules

This slice adds no new queue state. The generated read-data rules consume the
existing queue response-demux completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

For the last-beat sample, the same rule names capture into
`axi0_r0_last_rdata`/`axi0_r0_last_rresp` and
`axi0_r1_last_rdata`/`axi0_r1_last_rresp`.

## Validation

The implementation rejects dynamic issue-order queue read-data coverage unless
the response-demux completion source and read-data capture scope match one of
the two selected scalar shapes. It also rejects `read-data.read.burst-length`
metadata for this queue path.

Guarded validation passed for:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif
scripts/run_with_ram_guard.sh -- perl -Iperl <targeted parser/report/FSM probe>
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
```

The full focused HDL-lowering probe and strict CLI check were stopped by the
RAM guard while host memory was above the configured threshold. They were not
observed failing functionally; they did not complete in this memory window.

## Rollback

Rollback is localized to the `.467` slice:

- remove the two PPIF samples and support-accounting entries;
- remove the dynamic issue-order queue branch from read-data transaction
  coverage;
- remove the queue-specific read-data tests;
- remove this behavior record and its Knowledge Map fact card.

The underlying generated dynamic read issue-order queue behavior and ordinary
generated dynamic read-data behavior remain independent.
