# AXI IAL2 Manager Read Single-Beat Same-ID Queue-Head Response-Demux Behavior

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110`.

Date: `2026-06-15`.

## Purpose

This slice implements the bounded read single-beat concrete same-ID queue-head
behavior selected by `.109`.

It adds the public sample:

```text
ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
```

The sample has two read transactions, `r0` and `r1`, sharing concrete read ID
`3`. The read family selects:

```lisp
(same-id-ordering
  (read (concrete-id-reuse issue-order-queue)))
```

and read single-beat response demux:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

## Generated Behavior

For the covered shape, FSMGen now generates:

- compact one-hot depth-2 read queue slot state for concrete read ID `3`;
- admitted read request pulse storage for `r0` and `r1`;
- finite enqueue, dequeue, and same-cycle dequeue/enqueue update rules;
- generated read completion pulse outputs `axi0_r0_complete` and
  `axi0_r1_complete`;
- generated raw read response event and `RID` inputs;
- queue-head read `RID` demux rules without `RLAST`;
- read queue integrity assertions and read response-demux assertions.

The generated queue-head match for `r0` is:

```text
axi0_read_complete
&& axi0_rid == 4'd3
&& axi0_read_id3_same_id_issue_order_slot0_r0_q
```

The matching generated IAL1 rule is:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3)
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

`r1` uses the `slot0_r1` queue-head bit. The single-beat shape does not
declare or consume `axi0_rlast`, and it does not emit the non-last-beat
dequeue assertion used by the read burst-last queue-head sample.

## Report Surface

The read response-demux report now marks the covered single-beat queue-head arm
as generated:

```yaml
response_demux:
  read:
    mode: bounded_read_rid_queue_head_demux_contract
    response_scope: single_beat
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    transaction_completion_semantics: matched_concrete_id_queue_head
    generated_queue_behavior_boundary: generated_read_single_beat_queue_head_demux
```

The same-ID read policy reports:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    read:
      enforcement: generated_issue_order_queue
      implementation_status: generated_read_single_beat_queue_head_demux
      accepted_same_id_reuse: true
      generated_queue_behavior: true
```

The generated queue report lists concrete ID, depth, transaction order, slot
storage, enqueue pulses, generated update rules, and generated assertions. For
the covered shape, response-demux residue removes
`generated_same_id_queue_head_demux`, same-ID ordering residue is reduced to
`per_id_issue_order_queues`, and ID/response rule-engine residue removes
`same_id_ordering` and `response_demux`.

## Validation

Representative commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_single_beat_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
```

The focused generator and PPIF/CLI tests cover generated queue slot state,
update rules, completion outputs, `RID` demux rules without `RLAST`,
response/report residue, support accounting, and HDL verification.

## Deferred Work

Still deferred after this slice:

- read-data consumption of concrete same-ID queue-head demux;
- more than one duplicate concrete-ID group;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.
