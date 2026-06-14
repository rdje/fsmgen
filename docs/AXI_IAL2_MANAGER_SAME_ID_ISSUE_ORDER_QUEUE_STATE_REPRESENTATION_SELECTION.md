# AXI IAL2 Manager Same-ID Issue-Order Queue State Representation Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.101`

Date: 2026-06-14

## Purpose

This selector chooses the generated state representation for future bounded
AXI same-ID `issue-order-queue` behavior. It follows the `.100` readiness
audit, which found that admitted request pulses exist but queue-head response
demux cannot ship before queue identity state is precise.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, samples, support accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- current same-ID admitted request, response-demux, storage, rule,
  assertion, and expression helpers in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- public same-ID `issue-order-queue` and generated response-demux PPIF
  samples
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Selected Representation

The selected representation is:

```text
compact_onehot_transaction_slots
```

Each generated queue is:

- AXI profile-local;
- response-family-local (`read` or `write`);
- concrete-ID-value-local;
- selected only for a family whose public policy is
  `concrete-id-reuse issue-order-queue`;
- generated for concrete-ID groups that contain at least two authored
  concrete transactions sharing the same ID value.

The depth for a group remains the `.94` contract:

```text
min(<family max-pending>, <number of concrete transactions in the group>)
```

A depth of one is legal when `max-pending` is one. It allows the duplicate
concrete transaction inventory to become statically accepted only when later
queue-head demux behavior proves at most one same-ID transaction can be
active in that group.

Singleton concrete-ID groups do not need queue state. They remain covered by
the existing concrete request/response ID assertions and admitted request
metadata. They must not cause `accepted_same_id_reuse` or
`generated_queue_behavior` to become true.

## Storage Shape

The queue stores transaction identity as explicit one-hot bits per compacted
slot. It does not use arrays, dynamic indexed left-hand sides, pointer modulo
arithmetic, or hidden unbounded state.

For manager `axi0`, read concrete ID value `3`, transactions `r0` and `r1`,
and depth `2`, the selected storage names are:

```lisp
(var axi0_read_id3_same_id_issue_order_slot0_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot0_r1_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r1_q (width 1))
```

General form:

```text
<manager>_<family>_id<value>_same_id_issue_order_slot<slot>_<transaction>_q
```

The queue is compacted:

- slot `0` is the head;
- if slot `N` is nonempty, every slot `< N` must be nonempty;
- an empty queue has every slot bit clear;
- a full queue has at least one transaction bit set in the last slot.

No separate slot-valid bit is selected. A slot is nonempty when any
transaction bit in that slot is set:

```text
slot_nonempty(slot) = OR(slot_<slot>_<transaction>_q for each transaction)
```

The head transaction candidates are the slot `0` transaction bits. For the
example above:

```text
head_is_r0 = axi0_read_id3_same_id_issue_order_slot0_r0_q
head_is_r1 = axi0_read_id3_same_id_issue_order_slot0_r1_q
```

## Why One-Hot Slots

One-hot transaction bits are intentionally verbose. They fit the current
lowering path better than a compact encoded transaction ID plus head/tail
pointers:

- existing IAL1 storage already emits scalar width-bearing variables;
- rule actions already assign scalar targets from constants or other signals;
- boolean guards already support equality, less-than, AND, OR, NOT, and
  implication;
- response-demux guards can use one head bit directly;
- assertions can prove one-hot, compactness, and duplicate-transaction
  exclusion without dynamic indexing;
- the representation avoids new array ports, dynamic indexed LHS assignment,
  modulo arithmetic, shifts, or direct backend work.

## Queue Expressions

For each group:

```text
slot_nonempty(slot) = OR(slot bits for that slot)
queue_nonempty = slot_nonempty(0)
queue_full = slot_nonempty(depth - 1)
transaction_queued(txn) = OR(slot_<slot>_<txn>_q for every slot)
```

The future enqueue guard for transaction `txn` is based on the already
generated admitted request pulse:

```text
admitted_request_pulse(txn)
&& (!queue_full || queue_dequeue_event)
&& !transaction_queued(txn)
```

The `admitted_request_pulse(txn)` remains the source of admission truth. The
queue must not read the generated `can_accept` output.

## Update Semantics

The selected queue is a compact shift queue.

On enqueue only:

- append the admitted transaction into the first empty slot;
- keep lower occupied slots unchanged.

On dequeue only:

- remove slot `0`;
- shift every higher occupied slot down by one;
- clear the last slot.

On same-cycle dequeue plus enqueue:

- first remove the old head;
- shift the remaining old entries down;
- append the admitted transaction after the shifted entries;
- allow enqueue while the queue was full only if the dequeue event is true.

Implementation must generate finite case-specific rules from static depth and
slot occupancy predicates. It must not introduce dynamic indexing.

## Queue-Head Demux Interface

This selector names, but does not implement, the dequeue source:

```text
queue_dequeue_event(group)
```

That event must come from future queue-head response demux. For a selected
group, the intended match is:

```text
raw_response_event
&& response_id_signal == concrete_id
&& queue_nonempty
&& head_is_<transaction>
&& optional_last_signal_for_read_burst_last
```

The future demux rule pulses the authored transaction completion signal for
the head transaction and drives `queue_dequeue_event(group)`.

This cannot use the existing generated response-demux path as-is. Current
`response-demux` normalization requires `auto-id-lifecycle` metadata and
matches auto-ID `busy_signal` plus `selected_id_signal`. Concrete same-ID
queues need a concrete-ID queue-head response-demux contract.

## Report Vocabulary

The future generated queue report should live under the selected family:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      representation: compact_onehot_transaction_slots
      queue_depth_bound_source: max_pending_and_transaction_inventory
      issue_order_queues:
        - family: read
          concrete_id: 3
          depth: 2
          transactions: [r0, r1]
          storage:
            - slot: 0
              transaction_bits:
                r0: axi0_read_id3_same_id_issue_order_slot0_r0_q
                r1: axi0_read_id3_same_id_issue_order_slot0_r1_q
            - slot: 1
              transaction_bits:
                r0: axi0_read_id3_same_id_issue_order_slot1_r0_q
                r1: axi0_read_id3_same_id_issue_order_slot1_r1_q
          enqueue_event_source: admitted_request_pulse
          dequeue_event_source: queue_head_response_demux
          response_demux_strategy: queue_head_issue_order
```

Final behavior may set:

```yaml
enforcement: generated_issue_order_queue
accepted_same_id_reuse: true
generated_queue_behavior: true
```

only after both generated queue state and queue-head response demux are
present for the covered group. A representation-only or response-demux
contract-selection slice must keep those fields false.

## Required Assertions

Future behavior owners must include or preserve these checks for each
generated group:

- selected same-direction admitted request pulses remain mutually exclusive;
- each slot is one-hot-or-zero;
- the queue is compact;
- a transaction identity does not appear in more than one slot;
- enqueue is allowed only when the queue is not full or a same-cycle dequeue
  occurs;
- enqueue is rejected or asserted if the same transaction is already queued;
- dequeue implies the queue is nonempty;
- queue-head response demux matches at most one transaction;
- a raw selected-family response for a generated queue either matches a
  nonempty queue head or fails a runtime assertion selected by the future
  response-demux contract.

## Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`:

```text
Select AXI same-ID queue-head response-demux contract.
```

The representation is now explicit enough, but implementation is still not
the next safe owner. The public `response-demux` contract is currently
auto-ID-oriented. The next slice must select how concrete same-ID queue-head
demux is expressed, reported, and validated before queue state or duplicate
concrete same-ID acceptance changes.

## Non-Goals

This selector does not implement:

- duplicate concrete same-ID acceptance;
- generated queue storage or rules;
- queue-head response demux;
- response-demux parser changes;
- public sample changes;
- residue movement;
- direct backend lowering;
- VHDL.

## Validation For This Selector

Selector gates:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This selector changes only durable docs/task-tree state. Rolling it back
restores `.101` as the active representation-selection owner and does not
affect generated artifacts or public CLI behavior.
