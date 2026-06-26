# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.514`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.514` implements paired scalar read-data
routing over generated mixed dynamic/static read same-ID `issue-order-queue`
response-demux completions.

The covered public shapes are deliberately narrow:

- exactly one dynamic read transaction and one concrete static read
  transaction;
- exactly one generated mixed dynamic/static same-ID queue with depth 2;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- `response-demux.read` owns generated mixed dynamic/static queue completions;
- `read-data.read` uses existing scalar single-beat or scalar last-beat syntax;
- `read-data.read` covers the dynamic transaction followed by the static
  transaction exactly once;
- no `burst_length` metadata is admitted for this queue slice.

Raw `ARLEN`, runtime beat-count/RLAST validation, multi-beat output banks,
broader mixed queue cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-output generation, external converter
dependencies, and VHDL remain future exact-owner work.

## Public Samples

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data.ppif
```

They are registered as strict-supported PPIF entries:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data
```

with coverage buckets:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue_read_data_pipeline_cli
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_pipeline_cli
```

## Single-Beat Contract

The single-beat sample extends the generated mixed dynamic/static read
single-beat queue with scalar `RDATA`/`RRESP` capture:

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
mode: bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux
```

The read-data report uses queue-specific validity:

```text
mode: bounded_single_beat_read_data_contract
completion_validity: generated_mixed_dynamic_static_read_issue_order_queue_response_demux_completion_pulse
transactions: r0, r1
generated_inputs: axi0_rdata, axi0_rresp
generated_rules: axi0_r0_read_data_capture, axi0_r1_read_data_capture
residue: rlast_completion, bursts, multi_beat_read_data_reassembly
```

## Last-Beat Contract

The burst-last sample extends the generated mixed dynamic/static read
burst-last queue with scalar last-beat `RDATA`/`RRESP` capture:

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
mode: bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
```

The read-data report uses queue-specific last-beat validity:

```text
mode: bounded_last_beat_read_data_contract
completion_validity: generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
transactions: r0, r1
generated_inputs: axi0_rdata, axi0_rresp
generated_rules: axi0_r0_read_data_capture, axi0_r1_read_data_capture
residue: multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation, arlen_or_beat_count_validation
```

## Generated Rules

This slice adds no new queue state. The generated read-data rules consume the
existing mixed queue response-demux completion pulses:

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

The implementation rejects mixed dynamic/static issue-order queue read-data
coverage unless the response-demux completion source, capture scope, response
scope, transaction set, queue depth, and generated completion-signal count
match one of the selected scalar shapes. The read-data binding validator still
rejects missing, duplicate, or uncovered transaction bindings after the branch
selects the generated mixed queue transaction set.

Validation for `.514` is recorded in the task-tree verification log for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.514`.

## Rollback

Rollback is localized to the `.514` slice:

- remove the two PPIF samples and support-accounting entries;
- remove the mixed dynamic/static issue-order queue branch from read-data
  transaction coverage;
- remove the queue-specific read-data tests;
- remove this behavior record and its Knowledge Map fact card.

The underlying generated mixed dynamic/static read issue-order queue behavior
and ordinary generated mixed dynamic/static read-data behavior remain
independent.
