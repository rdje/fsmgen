# AXI IAL2 Manager Write Depth-3 Queue-Head Response-Demux Behavior

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.171`.

Date: `2026-06-17`.

## Purpose

This slice implements the bounded write-family depth-3 concrete same-ID
queue-head response-demux behavior selected by `.170`.

It adds the public sample:

```text
ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
```

The sample has three write transactions, `w0`, `w1`, and `w2`, sharing
concrete write ID `3`. The write family selects:

```lisp
(same-id-ordering
  (write (concrete-id-reuse issue-order-queue)))
```

and write response demux:

```lisp
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

## Generated Behavior

For the covered shape, FSMGen now generates:

- compact one-hot depth-3 write queue slot state for concrete write ID `3`;
- admitted write request pulse storage for `w0`, `w1`, and `w2`;
- finite enqueue, dequeue, and same-cycle dequeue/enqueue update rules;
- generated write completion pulse outputs `axi0_w0_complete`,
  `axi0_w1_complete`, and `axi0_w2_complete`;
- generated raw write response event and `BID` inputs;
- queue-head write `BID` demux rules;
- write queue integrity assertions and write response-demux assertions.

The generated queue-head match for `w2` is:

```text
axi0_write_complete
&& axi0_bid == 4'd3
&& axi0_write_id3_same_id_issue_order_slot0_w2_q
```

The matching generated IAL1 rule is:

```lisp
(rule axi0_w2_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w2_q)
  (pulse axi0_w2_complete))
```

The schedule report lists one generated write queue:

```text
queue=3:w0/w1/w2:d3
slot_storage=9
generated_update_rules=54
generated_queue_assertions=14
generated_response_demux_rules=3
generated_response_demux_assertions=4
```

## Report Surface

The write response-demux report marks the covered write queue-head arm as
generated:

```yaml
response_demux:
  write:
    mode: bounded_write_bid_queue_head_demux_contract
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    transaction_completion_semantics: matched_concrete_id_queue_head
    generated_queue_behavior_boundary: generated_write_bid_queue_head_demux
```

The same-ID write policy reports:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    write:
      enforcement: generated_issue_order_queue
      implementation_status: generated_write_bid_queue_head_demux
      accepted_same_id_reuse: true
      generated_queue_behavior: true
```

For the covered sample, response-demux residue removes
`generated_same_id_queue_head_demux`, same-ID ordering residue is reduced to
`per_id_issue_order_queues`, and ID/response rule-engine residue removes
`same_id_ordering` and `response_demux`.

Strict check JSON and normalized semantic JSON support-account the sample as:

```text
intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_write_depth3_same_id_queue_head_response_demux_pipeline_cli
```

## Boundaries

This slice does not enable read-data, burst-length, runtime-validation,
multi-beat payload, read response-demux, `RLAST`, write multi-group depth-3,
mixed read/write depth-3, mixed depth-2/depth-3 generated groups, same-family
mixed auto-ID plus concrete queue-head demux, group-local simultaneous enqueue
widening, packed outputs, alternate burst assembly, direct backend,
verification-output generation, VHDL, or backend-language variants.

Existing write depth-2 one-group and multi-group samples, read depth-3
response-demux/read-data/burst-length/runtime-validation/multi-beat samples,
support accounting, and HDL verification behavior remain preserved.

## Validation

Representative commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_write_depth3_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
```

