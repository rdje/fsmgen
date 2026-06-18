# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Last-Beat Read-Data Behavior

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.180`.

Date: `2026-06-18`.

## Purpose

This slice implements the bounded read burst-last behavior selected by `.179`:
generated scalar last-beat `RDATA`/`RRESP` capture over generated read
burst-last concrete same-ID queue-head response-demux groups where every
duplicate concrete `RID` group has computed depth `2` or `3` and at least one
group has depth `3`.

It adds these public `.ppif` samples:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif
```

The `multi_depth3` sample contains two independent depth-3 duplicate-`RID`
groups:

```text
RID 3: r0, r1, r2
RID 5: r3, r4, r5
```

The `mixed_depth3_depth2` sample contains one depth-3 group and one depth-2
group:

```text
RID 3: r0, r1, r2
RID 5: r3, r4
```

## Generated Behavior

For every transaction in each covered queue group, FSMGen now generates:

- generated `axi0_rid`, `axi0_rlast`, `axi0_rdata`, and `axi0_rresp` inputs;
- generated read burst-last queue-head response-demux completion pulses;
- scalar per-transaction last-beat data/status outputs such as
  `axi0_r5_last_rdata` and `axi0_r5_last_rresp`;
- read-data capture rules guarded by generated queue-head last-beat completion
  pulses;
- SystemVerilog capture enables driven by those generated completion pulses;
- no `axi0_arlen`, beat-count state, runtime beat-count/`RLAST` validation,
  per-beat output bank, packed payload vector, or aggregate-only status output.

Representative generated last-beat capture rule for the last transaction in
the two-depth-3 sample:

```lisp
(rule axi0_r5_read_data_capture axi0_r5_complete
  (axi0_r5_last_rdata axi0_rdata)
  (axi0_r5_last_rresp axi0_rresp))
```

The matching queue-head response-demux guard remains `RLAST`-gated:

```lisp
(rule axi0_r5_response_demux
  (& axi0_read_complete (== axi0_rid 4'd5) axi0_rlast
     axi0_read_id5_same_id_issue_order_slot0_r5_q)
  (pulse axi0_r5_complete))
```

## Report Surface

The generated response-demux boundary remains:

```text
generated_read_burst_last_queue_head_demux
```

The read-data report marks:

```yaml
read_data:
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    data_signal: axi0_rdata
    status_signal: axi0_rresp
    status_policy: last_beat
    interleaving: last_beat_by_rid
  residue:
    - multi_beat_read_data_reassembly
    - per_beat_outputs
    - rresp_aggregation
    - arlen_or_beat_count_validation
```

Generated scalar read-data artifacts are transaction-list driven:

| Sample | Read-data transactions | Generated outputs | Generated capture rules |
| --- | --- | ---: | ---: |
| two depth-3 groups | `r0 r1 r2 r3 r4 r5` | 12 | 6 |
| mixed depth-3/depth-2 groups | `r0 r1 r2 r3 r4` | 10 | 5 |

The response-demux report still lists the generated same-ID queue-head groups
under `response_demux.read.same_id_issue_order_queues`, with generated
completion signals and one `RLAST`-gated response-demux rule per transaction.

## Admission Boundary

The generated behavior is limited to:

- read family only;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`/`RLAST`;
- `read-data.read.capture-scope last-beat`;
- `read-data.read.completion-source response-demux`;
- `read-data.read.status-policy last-beat`;
- `read-data.read.interleaving last-beat-by-rid`;
- generated read burst-last queue-head response-demux completion pulses;
- scalar last-beat `RDATA`/`RRESP` outputs for every covered transaction;
- duplicate concrete read-ID groups whose computed depth is `2` or `3`, with
  at least one depth-3 group;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- no `burst_length` metadata;
- no same-family `auto-id-lifecycle` demux in the same sample.

This slice widens only the local no-`burst_length` last-beat read-data coverage
admission predicate. Existing read-data normalization, generated artifact
enumeration, report projection, and HDL lowering remain transaction-list
driven.

## Support Accounting And Semantic Introspection

The public samples are support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data
intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data
```

Strict check JSON and normalized semantic JSON report those entry IDs, the
`supported_smoke` classification, dedicated coverage buckets, and generated
module `axi0_capacity_status`.

## Preserved Behavior

The following remain generated and support-accounted with their prior behavior:

- read burst-last depth-2 one-group and multi-group queue-head read-data;
- read burst-last one-depth-3 queue-head read-data;
- read burst-last depth-3 report-only burst-length, runtime-validation, and
  multi-beat output-bank samples;
- `.174` multiple/mixed depth-3 response-demux-only samples;
- `.177` multiple/mixed depth-3 single-beat read-data samples;
- write queue-head response-demux samples.

## Deferred Work

The following remain outside this slice:

- burst-length metadata over multiple/mixed depth-3 queue-head read-data;
- runtime beat-count/`RLAST` validation over multiple/mixed depth-3 queue-head
  read-data;
- multi-beat payload behavior over multiple/mixed depth-3 queue-head groups;
- write-family read-data;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs and alternate full burst payload assembly;
- direct IAL2-to-backend lowering;
- verification-output generation;
- VHDL and backend-language variants.

## Validation

Representative commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_axi_read_burst_last_multi_depth3_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif
```
