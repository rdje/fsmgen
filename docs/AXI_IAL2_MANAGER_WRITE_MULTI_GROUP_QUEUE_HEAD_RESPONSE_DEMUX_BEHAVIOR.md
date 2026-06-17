# AXI IAL2 Manager Write Multi-Group Queue-Head Response-Demux Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.140` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.140`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_write_multi_group_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
```

The sample selects:

```lisp
(same-id-ordering
  (write (concrete-id-reuse issue-order-queue)))
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

It has two duplicate concrete write-ID groups:

- `w0` and `w1` share concrete `BID` `3`;
- `w2` and `w3` share concrete `BID` `5`.

There is no `read_data` clause.

## Generated Behavior

FSMGen now generates bounded write queue-head response-demux behavior for one
or more independent duplicate concrete write-ID groups when every generated
group has exactly two write transactions and computed depth `2`.

For each covered group, generation emits:

- concrete-ID-scoped compact one-hot queue slot storage;
- per-transaction admitted write-request pulse storage;
- finite queue transition rules;
- generated write completion pulse outputs;
- queue-head `BID` response-demux rules;
- queue assertions and write response-demux assertions;
- generated queue reports under `same_id_ordering`;
- residue movement that removes `generated_same_id_queue_head_demux`.

The generated rule for the first transaction in the `BID` `5` group is:

```lisp
(rule axi0_w2_response_demux
  (& axi0_write_complete (== axi0_bid 4'd5)
     axi0_write_id5_same_id_issue_order_slot0_w2_q)
  (pulse axi0_w2_complete))
```

The schedule report marks:

```text
response_demux.generated_behavior: true
response_demux.write.generated_queue_behavior_boundary:
  generated_write_bid_queue_head_demux
response_demux.write.generated_completion_signals:
  axi0_w0_complete
  axi0_w1_complete
  axi0_w2_complete
  axi0_w3_complete
response_demux.write.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [w0, w1]
    depth: 2
  - concrete_id: 5
    transactions: [w2, w3]
    depth: 2
response_demux.residue:
  read_response_demux
  read_data_interleaving
  bursts
```

The write same-ID policy reports both generated queues, keeps
`implementation_status: generated_write_bid_queue_head_demux`, and records
`accepted_same_id_reuse: true` plus `generated_queue_behavior: true`.

## Admission Boundary

The admission contract remains family-wide. A single generated
`axi0_write_issue_order_queue_request_onehot0` assertion covers all selected
write request events for the manager object. This slice does not claim
group-local simultaneous same-cycle enqueue support for different concrete
write IDs.

The generated behavior stays limited to:

- write family only;
- generated queue-head response demux only;
- duplicate concrete write-ID groups;
- exactly two write transactions per covered group;
- computed queue depth `2`;
- selected `same-id-ordering.write concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` demux.

## Support Accounting

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux
```

Strict check JSON and normalized semantic JSON report that entry and keep the
generated module name `axi0_capacity_status`.

## Preserved Behavior

The existing one-group write queue-head response-demux sample remains
generated. Read burst-last multi-group queue-head response-demux, read
single-beat one-group queue-head response-demux, generated queue-head
read-data, burst-length, runtime-validation, and multi-beat queue-head samples
remain within their previous boundaries.

## Deferred Work

The following remain outside this slice:

- read single-beat multi-group queue-head behavior;
- additional queue-depth widening beyond the later selected one-group
  depth-3 read single-beat response-demux/read-data shapes;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening;
- packed outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
