# AXI IAL2 Manager Write Same-ID Queue-Head Response-Demux Behavior

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.108`.

Date: `2026-06-15`.

## Purpose

This slice implements the bounded write-family concrete same-ID queue-head
behavior selected by `.107`.

It adds the public sample:

```text
ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
```

The sample has two write transactions, `w0` and `w1`, sharing concrete write
ID `3`. The write family selects:

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

- compact one-hot depth-2 write queue slot state for concrete write ID `3`;
- admitted write request pulse storage for `w0` and `w1`;
- finite enqueue, dequeue, and same-cycle dequeue/enqueue update rules;
- generated write completion pulse outputs `axi0_w0_complete` and
  `axi0_w1_complete`;
- generated raw write response event and `BID` inputs;
- queue-head write `BID` demux rules;
- write queue integrity assertions and write response-demux assertions.

The generated queue-head match for `w0` is:

```text
axi0_write_complete
&& axi0_bid == 4'd3
&& axi0_write_id3_same_id_issue_order_slot0_w0_q
```

The matching generated IAL1 rule is:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w0_q)
  (pulse axi0_w0_complete))
```

`w1` uses the `slot0_w1` queue-head bit.

## Report Surface

The write response-demux report now marks the covered write queue-head arm as
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

The generated queue report lists concrete ID, depth, transaction order, slot
storage, enqueue pulses, generated update rules, and generated assertions.
For the covered shape, response-demux residue removes
`generated_same_id_queue_head_demux`, same-ID ordering residue is reduced to
`per_id_issue_order_queues`, and ID/response rule-engine residue removes
`same_id_ordering` and `response_demux`.

## HDL Assertion Repair

The `.108` HDL gate exposed a generic assertion-rendering issue: immediate
runtime assertions could reference factored intermediate expressions that were
created only for assertion conditions and therefore were not emitted as
SystemVerilog wires. The fix is in
`FSM::Pipeline::GeneratedModuleInfoBuilder`: assertion condition rendering now
recursively inlines intermediate signal references inside CoreAST boolean
trees before the verification-only SVA block is appended.

This keeps regular generated-HDL factorization unchanged while making both the
new write queue-head sample and the existing read queue-head sample pass
`--verify-hdl`.

## Validation

Representative commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_write_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
```

The focused generator and PPIF/CLI tests cover generated queue slot state,
update rules, completion outputs, `BID` demux rules, response/report residue,
support accounting, and HDL verification.

## Deferred Work

Still deferred after this slice:

- read `single-beat` concrete same-ID queue-head behavior;
- more than one duplicate concrete-ID group;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- read-data consumption of concrete same-ID queue-head demux;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.
