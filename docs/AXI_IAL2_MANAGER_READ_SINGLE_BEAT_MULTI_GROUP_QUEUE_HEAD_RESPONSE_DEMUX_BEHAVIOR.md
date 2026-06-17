# AXI IAL2 Manager Read Single-Beat Multi-Group Queue-Head Response-Demux Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.143` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.143`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_multi_group_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif
```

The sample selects:

```lisp
(same-id-ordering
  (read (concrete-id-reuse issue-order-queue)))
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

It has two duplicate concrete read-ID groups:

- `r0` and `r1` share concrete `RID` `3`;
- `r2` and `r3` share concrete `RID` `5`.

There is no `last-signal` and no `read_data` clause.

## Generated Behavior

FSMGen now generates bounded read single-beat queue-head response-demux
behavior for one or more independent duplicate concrete read-ID groups when
every generated group has exactly two read transactions and computed depth `2`.

For each covered group, generation emits:

- concrete-ID-scoped compact one-hot queue slot storage;
- per-transaction admitted read-request pulse storage;
- finite queue transition rules;
- generated read completion pulse outputs;
- queue-head `RID` response-demux rules without `RLAST`;
- queue assertions and read response-demux assertions;
- generated queue reports under `same_id_ordering`;
- residue movement that removes `generated_same_id_queue_head_demux`.

The generated rule for the first transaction in the `RID` `5` group is:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd5)
     axi0_read_id5_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

The schedule report marks:

```text
response_demux.generated_behavior: true
response_demux.read.generated_queue_behavior_boundary:
  generated_read_single_beat_queue_head_demux
response_demux.read.generated_completion_signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
  axi0_r3_complete
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1]
    depth: 2
  - concrete_id: 5
    transactions: [r2, r3]
    depth: 2
response_demux.residue:
  read_data_interleaving
  bursts
```

The read same-ID policy reports both generated queues, keeps
`implementation_status: generated_read_single_beat_queue_head_demux`, and
records `accepted_same_id_reuse: true` plus
`generated_queue_behavior: true`.

## Admission Boundary

The admission contract remains family-wide. A single generated
`axi0_read_issue_order_queue_request_onehot0` assertion covers all selected
read request events for the manager object. This slice does not claim
group-local simultaneous same-cycle enqueue support for different concrete
read IDs.

The generated behavior stays limited to:

- read family only;
- `response-demux.read.response-scope single-beat` only;
- generated queue-head response demux only;
- duplicate concrete read-ID groups;
- exactly two read transactions per covered group;
- computed queue depth `2`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` demux;
- no `last-signal` and no `read_data` clause.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the exact coverage bucket, and the generated
module name `axi0_capacity_status`. That keeps the deep semantic
introspection surface used by MCP clients aligned with the user-facing support
catalog instead of relying on an implicit CLI-only behavior claim.

## Preserved Behavior

The existing read single-beat one-group queue-head response-demux sample
remains generated. Read burst-last multi-group queue-head response-demux,
write multi-group queue-head response-demux, generated queue-head read-data,
burst-length, runtime-validation, and multi-beat queue-head samples remain
within their previous boundaries.

## Deferred Work

The following remain outside this slice:

- read-data over multiple read single-beat queue-head groups;
- additional queue-depth widening beyond the later selected one-group
  depth-3 read single-beat response-demux/read-data shapes;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
