# AXI IAL2 Manager Read Burst-Last Depth-3 Queue-Head Response-Demux Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.156` on
2026-06-17.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.156`

## Public Sample

The runnable PPIF sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_burst_last_depth3_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
```

The sample selects:

```lisp
(same-id-ordering
  (read (concrete-id-reuse issue-order-queue)))
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

It has one duplicate concrete read-ID group: `r0`, `r1`, and `r2` share
concrete `RID` `3`. The read pending depth is `3`, so the generated same-ID
issue-order queue has computed depth `3`.

There is no `read_data`, `burst_length`, runtime beat-count validation,
multi-beat output bank, packed burst vector, or status aggregation in this
response-demux-only sample.

## Generated Behavior

FSMGen now generates bounded read burst-last queue-head response-demux
behavior for exactly one duplicate concrete read-ID group with three read
transactions and computed depth `3`.

Generation emits:

- compact one-hot queue slot storage for `slot0`, `slot1`, and `slot2`;
- per-transaction admitted read-request pulse storage;
- shared enumerated queue transition rules over compact queue states;
- generated read completion pulse outputs for `r0`, `r1`, and `r2`;
- generated `RID` and one-bit `RLAST` inputs;
- queue-head `RID`/`RLAST` response-demux rules;
- generalized slot onehot, compactness, unique-slot, response-nonempty,
  response-unique-head, non-last-no-dequeue, enqueue-space-or-dequeue, and
  duplicate-after-dequeue assertions;
- generated queue reports under `same_id_ordering`;
- residue movement that removes `generated_same_id_queue_head_demux` for this
  selected read burst-last response-demux-only shape.

The generated rule for `r2` is:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

The generated queue state includes third-slot storage such as:

```lisp
(var axi0_read_id3_same_id_issue_order_slot2_r2_q (width 1))
```

The schedule report marks:

```text
response_demux.generated_behavior: true
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.generated_completion_signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1, r2]
    depth: 3
response_demux.residue:
  read_data_interleaving
  bursts
```

The read same-ID policy reports the generated depth-3 queue, keeps
`implementation_status: generated_read_burst_last_queue_head_demux`, and
records `accepted_same_id_reuse: true` plus
`generated_queue_behavior: true`.

## Queue Semantics

The covered queue uses the same compact one-hot transaction-slot semantics as
the existing depth-2 burst-last queue-head behavior and the depth-3
single-beat sibling.

For the covered depth-3 shape, each generated transition:

- starts from one compact queue sequence;
- optionally dequeues the active head transaction only when the raw read
  response event is asserted, the concrete `RID` matches, `RLAST` is asserted,
  and the head slot names that transaction;
- shifts remaining active entries toward `slot0`;
- optionally appends the single admitted request at the tail after any shift;
- leaves state unchanged on non-last beats and emits a non-last no-dequeue
  assertion for the selected queue.

The admission boundary remains family-wide. A single generated
`axi0_read_issue_order_queue_request_onehot0` assertion covers the selected
read request events for the manager object. This slice does not claim
group-local simultaneous same-cycle enqueue support beyond that existing
one-admitted-request boundary.

## Support Accounting And Semantic Introspection

The public sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux
```

Strict check JSON and normalized semantic JSON report that entry, the
`supported_smoke` classification, the coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux_pipeline_cli`,
and the generated module name `axi0_capacity_status`.

## Preserved Behavior

Existing depth-2 queue-head samples remain within their previous boundaries:
read burst-last one-group and multi-group response-demux, read burst-last
queue-head read-data, raw-`ARLEN`, runtime-validation and multi-beat read-data,
read single-beat one-group and multi-group response-demux/read-data, and
write-family queue-head response-demux remain generated for their shipped
shapes.

The depth-3 read single-beat response-demux and scalar read-data siblings stay
generated without `RLAST`. This slice only adds the depth-3 burst-last
response-demux-only sibling.

## Deferred Work

The following remain outside this slice:

- read-data over read burst-last depth-3 response-demux;
- burst-length, runtime-validation, or multi-beat read-data over read
  burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head response demux;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.
