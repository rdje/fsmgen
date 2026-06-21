# AXI IAL2 Manager Mixed Auto-ID Queue-Head Read-Data Behavior

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.197`

Date: 2026-06-21

## Scope

This slice ships scalar read-data consumption for the read-side mixed family
introduced by `.194`:

- one same-family `auto-id-lifecycle` read transaction;
- one concrete duplicate-ID `same-id-ordering` `issue-order-queue` group with
  depth 2 under the same selected read `response-demux`;
- existing `read-data` syntax with `completion-source response-demux`.

The supported public shapes are:

- read `response-scope single-beat` with scalar `RDATA`/`RRESP`;
- read `response-scope burst-last` with one-bit `RLAST` and scalar last-beat
  `RDATA`/`RRESP`.

No new PPIF syntax is introduced. The public fixtures are:

- `ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif`

## Source Shape

The single-beat fixture combines one auto-ID read transaction with two
concrete read transactions that share concrete ID `3`:

```lisp
(transactions
  (read r0 (request axi0_r0_request) (completion axi0_r0_complete) (id auto))
  (read r1 (request axi0_r1_request) (completion axi0_r1_complete) (id (value 3)))
  (read r2 (request axi0_r2_request) (completion axi0_r2_complete) (id (value 3))))
(auto-id-lifecycle
  (read (pool 0 1)))
(same-id-ordering
  (read (concrete-id-reuse issue-order-queue)))
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
    (transaction r0 (data-output axi0_r0_rdata) (status-output axi0_r0_rresp))
    (transaction r1 (data-output axi0_r1_rdata) (status-output axi0_r1_rresp))
    (transaction r2 (data-output axi0_r2_rdata) (status-output axi0_r2_rresp))))
```

The burst-last fixture uses the same transaction family and adds:

```lisp
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
    (transaction r0 (data-output axi0_r0_last_rdata) (status-output axi0_r0_last_rresp))
    (transaction r1 (data-output axi0_r1_last_rdata) (status-output axi0_r1_last_rresp))
    (transaction r2 (data-output axi0_r2_last_rdata) (status-output axi0_r2_last_rresp))))
```

## Generated Behavior

The read response demux reports
`transaction_completion_source: generated_demux_and_queue_head_demux`.
Read-data coverage now consumes the combined completion set from that demux:

- `r0` is the auto-ID transaction completion;
- `r1` and `r2` are concrete queue-head completions from the depth-2 same-ID
  issue-order queue;
- the burst-last completion rules include `RLAST`.

For the single-beat shape, read-data reports:

```text
completion_validity: generated_mixed_auto_id_queue_head_response_demux_completion_pulse
transactions: r0, r1, r2
```

For the burst-last shape, read-data reports:

```text
completion_validity: generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
transactions: r0, r1, r2
```

Generated IAL1 declares the read response inputs and one data/status output
pair per transaction. The scalar capture rules are guarded by the generated
completion pulse for each transaction. For the final concrete transaction in
the single-beat fixture, the generated rule is equivalent to:

```lisp
(rule axi0_r2_read_data_capture axi0_r2_complete
  (axi0_r2_rdata axi0_rdata)
  (axi0_r2_rresp axi0_rresp))
```

The emitted SystemVerilog exposes `ARID` as the generated request-ID output,
`RID`/`RDATA`/`RRESP` as inputs, and the transaction data/status captures as
registered outputs. The concrete queue-head demux guard remains part of the
completion pulse, so the read-data capture reuses the generated response-demux
identity decision rather than re-matching `RID`.

## Validation Surface

Both new fixtures are support-accounted under:

- `intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data`
- `intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data`

For both fixtures:

- `--strict --check --json` succeeds;
- `--emit-schedule-json` reports the mixed response demux and generated
  read-data behavior;
- `--strict --emit-semantic-json` is support-accounted;
- `--verify-hdl` passes through the current Verilator/Yosys validation lane.

## Non-Goals

The slice does not add:

- new PPIF syntax;
- mixed multi-beat output-bank behavior;
- burst-length capture or runtime beat-count/`RLAST` validation over mixed
  families;
- group-local simultaneous enqueue widening;
- write-family read-data behavior;
- packed burst-vector outputs or alternate full burst payload assembly;
- direct IAL2-to-IAL0 lowering;
- verification-output generation;
- VHDL or backend-language variants.
