# AXI IAL2 Manager Same-ID Queue Behavior First Slice

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.106`.

Date: `2026-06-14`.

## Purpose

This slice implements the first generated AXI same-ID issue-order queue
behavior selected by `.105`. It is intentionally bounded to the existing
public read burst-last queue-head sample shape:

- read family only;
- one duplicate concrete read-ID group;
- concrete ID value `3` in the public sample;
- two read transactions, `r0` and `r1`;
- computed queue depth `2`;
- `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`;
- no same-family auto-ID lifecycle;
- no read-data consumption of this concrete queue-head demux.

The public sample remains:

```text
ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

## Generated Interface Ownership

For the covered shape, transaction completion events are no longer authored
inputs. They are generated pulse outputs:

```lisp
(output axi0_r0_complete)
(output axi0_r1_complete)
```

The raw accepted read response beat and response metadata become generated
inputs:

```lisp
(input axi0_read_complete)
(input axi0_rid (width 4))
(input axi0_rlast)
```

The generated completion pulses still drive the existing read completion
fan-in used by capacity/status accounting.

## Queue State

The generated queue state uses the compact one-hot transaction-slot
representation selected by `.101`:

```lisp
(var axi0_read_id3_same_id_issue_order_slot0_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot0_r1_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r1_q (width 1))
```

Slot `0` is the queue head. The first implementation does not introduce
arrays, dynamic indexed left-hand sides, pointer modulo arithmetic, hidden
unbounded queues, or direct-backend-only behavior.

## Queue Update Rules

FSMGen generates the finite depth-2 table from `.105` using admitted request
pulses and queue-head last-beat response matches. Example generated rules
include:

```lisp
(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0 ...)
(rule axi0_read_id3_same_id_issue_order_r0_dequeue ...)
(rule axi0_read_id3_same_id_issue_order_r0_dequeue_enqueue_r1 ...)
(rule axi0_read_id3_same_id_issue_order_r0_r1_dequeue_enqueue_r0 ...)
```

The generated rules cover enqueue-only, dequeue-only, and legal same-cycle
dequeue-plus-enqueue cases for:

```text
empty
[r0]
[r1]
[r0, r1]
[r1, r0]
```

The ISF lowerer does not prove all negated compound queue-head matches
disjoint, so this slice emits explicit priorities across the generated
transition rules. The queue integrity assertions still define the legality
boundary; priorities make the generated IAL1 deterministic for the lowerer.

## Queue-Head Demux

The generated response-demux match for `r0` is:

```text
axi0_read_complete
&& axi0_rid == 4'd3
&& axi0_rlast
&& axi0_read_id3_same_id_issue_order_slot0_r0_q
```

The `r1` match uses the `slot0_r1` head bit. The generated completion rules
are:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))

(rule axi0_r1_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r1_q)
  (pulse axi0_r1_complete))
```

## Assertions

The slice preserves admitted request mutual-exclusion assertions and adds
queue integrity assertions for:

- slot one-hot-or-empty;
- compactness;
- one transaction identity appearing in at most one slot;
- enqueue only when space exists or a selected dequeue occurs;
- no duplicate transaction remaining after the selected dequeue;
- response for the covered concrete ID requiring a nonempty queue;
- unique queue-head response match;
- dequeue only from a nonempty queue;
- non-last matching beats not dequeuing.

The response-demux active/unique assertions are scoped to:

```text
axi0_read_complete && axi0_rid == 4'd3
```

Different-ID interleaving and broader queue coverage remain outside this first
implementation boundary.

## Report Movement

For the public sample, schedule JSON now reports:

```yaml
response_demux:
  generated_behavior: true
  read:
    mode: bounded_read_rid_queue_head_demux_contract
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
```

The same-ID ordering policy now reports:

```yaml
same_id_ordering:
  generated_behavior: true
  concrete_id_reuse_policy:
    read:
      enforcement: generated_issue_order_queue
      implementation_status: generated_read_burst_last_queue_head_demux
      accepted_same_id_reuse: true
      generated_queue_behavior: true
      queue_state_representation: compact_onehot_transaction_slots
```

`same_id_ordering.concrete_id_reuse_policy.read.generated_queues` lists the
concrete ID, depth, transaction order, slot storage, enqueue pulses, generated
update rules, and generated assertions. The response-demux residue removes
`generated_same_id_queue_head_demux`; the ID/response residue removes
`same_id_ordering` and `response_demux` for this covered shape.

## Deferred Work

The following remain deferred until separately owned:

- write same-ID queue-head behavior;
- read `single-beat` concrete same-ID queue-head behavior;
- more than one duplicate concrete-ID group;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- read-data consumption of concrete same-ID queue-head demux;
- different-ID interleaving beyond the covered ID;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Validation

Focused validation for this slice included:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB prove -Iperl t/1436-ial2-ppif-parser-cli.t
```

The PPIF/CLI proof exercises schedule JSON, check JSON, semantic JSON, and
generated artifact paths for the public sample.
