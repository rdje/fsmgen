# AXI IAL2 Manager Same-ID Queue Behavior First Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`.

Date: `2026-06-14`.

## Purpose

This selector chooses the first generated behavior slice after `.104` found no
new lower-layer substrate prerequisite, but also found that same-ID queue state
and queue-head response demux must be specified together before runtime
behavior changes.

This slice is documentation and task-tree state only. It does not change
parser, generator, tests, samples, support accounting, generated artifacts, or
HDL behavior.

## Selected First Behavior Boundary

The first implementation owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.106`, generated AXI same-ID read burst-last
queue behavior for the existing queue-head response-demux sample shape.

The generated behavior boundary is intentionally narrow:

- one selected `read` family only;
- public `response-demux.read.response-scope burst-last`;
- one-bit `last-signal`;
- `transaction-completion generated`;
- exactly one duplicate concrete read-ID group;
- exactly two read transactions in that group;
- computed queue depth exactly `2`;
- no same-family `auto-id-lifecycle`;
- no read-data consumption of the concrete same-ID queue-head demux;
- no write queue-head behavior in the first implementation slice;
- no same-family mixed auto-ID plus concrete same-ID queue-head behavior.

The existing public sample is the target shape:

```text
ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

It contains read transactions `r0` and `r1`, both with concrete ID value `3`.
The first behavior slice may set generated behavior true only for this covered
shape. Wider shapes must remain selected-not-generated until later owners.

## Generated State

For manager `axi0`, read ID value `3`, transactions `r0` and `r1`, and depth
`2`, `.106` should generate the compact one-hot slot storage selected by
`.101`:

```lisp
(var axi0_read_id3_same_id_issue_order_slot0_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot0_r1_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r0_q (width 1))
(var axi0_read_id3_same_id_issue_order_slot1_r1_q (width 1))
```

Slot `0` is the queue head. The first implementation must not introduce
arrays, dynamic indexed left-hand sides, hidden unbounded queues, pointer modulo
arithmetic, or direct backend-only behavior.

## Generated Match And Completion

The queue-head response match for `r0` is:

```text
axi0_read_complete
&& axi0_rid == 4'd3
&& axi0_rlast
&& axi0_read_id3_same_id_issue_order_slot0_r0_q
```

The queue-head response match for `r1` is the same expression with the `r1`
head bit. The response-demux rules should pulse generated transaction
completion outputs:

```lisp
(output axi0_r0_complete)
(output axi0_r1_complete)

(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

`axi0_r0_complete` and `axi0_r1_complete` stop being authored inputs for this
covered generated shape. They become generated completion pulse outputs and
drive read capacity release through the existing completion fan-in path.

The internal queue dequeue event is the logical OR of the generated queue-head
last-beat matches. It does not need to be a separate storage pulse in the first
implementation; queue update rules may use the same static match predicates
directly to avoid a delayed dequeue pulse dependency.

## Queue Update Table

The first implementation must generate a finite depth-2 transition table from
the legal compact states:

```text
empty
[r0]
[r1]
[r0, r1]
[r1, r0]
```

Let:

- `e0` be `axi0_r0_admitted_request_pulse_q`;
- `e1` be `axi0_r1_admitted_request_pulse_q`;
- `m0` be the generated last-beat queue-head response match for `r0`;
- `m1` be the generated last-beat queue-head response match for `r1`;
- `d` be `m0 || m1`.

The transition semantics are:

| Old state | Event | New state |
| --- | --- | --- |
| `empty` | `e0` | `[r0]` |
| `empty` | `e1` | `[r1]` |
| `[r0]` | `m0` | `empty` |
| `[r1]` | `m1` | `empty` |
| `[r0]` | `e1` | `[r0, r1]` |
| `[r1]` | `e0` | `[r1, r0]` |
| `[r0]` | `m0 && e0` | `[r0]` |
| `[r0]` | `m0 && e1` | `[r1]` |
| `[r1]` | `m1 && e0` | `[r0]` |
| `[r1]` | `m1 && e1` | `[r1]` |
| `[r0, r1]` | `m0` | `[r1]` |
| `[r1, r0]` | `m1` | `[r0]` |
| `[r0, r1]` | `m0 && e0` | `[r1, r0]` |
| `[r1, r0]` | `m1 && e1` | `[r0, r1]` |

Hold cases need no generated rule if the existing storage semantics preserve
state when no rule fires. Illegal event combinations must be covered by
generated assertions rather than silently skipped.

Duplicate-transaction checks are evaluated after the selected dequeue. This
allows a transaction to be re-enqueued in the same cycle only when its old
instance was the dequeued head. It rejects re-enqueue of a transaction that
remains in the shifted queue.

## Generated Assertions

`.106` must generate or preserve assertions for:

- selected read admitted request pulses are mutually exclusive;
- each slot is one-hot-or-zero;
- slot `1` nonempty implies slot `0` nonempty;
- a transaction identity appears in at most one slot;
- an admitted enqueue is valid only when the queue is not full or a dequeue
  occurs in the same cycle;
- an admitted enqueue does not duplicate a transaction remaining after
  dequeue;
- a concrete-ID read response beat for the covered ID requires a nonempty
  queue;
- a queue-head response match is unique;
- a generated dequeue occurs only from a nonempty queue;
- matched non-last beats do not dequeue and do not pulse transaction
  completion.

The response-demux active-match assertion should be scoped to accepted read
response beats whose `RID` equals the covered concrete ID. Wider different-ID
interleaving remains outside the first implementation boundary.

## Report Movement

For the covered sample, `.106` may report:

```yaml
same_id_ordering:
  generated_behavior: true
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: generated_issue_order_queue
      implementation_status: generated_read_burst_last_queue_head_demux
      accepted_same_id_reuse: true
      generated_queue_behavior: true
      queue_state_representation: compact_onehot_transaction_slots
```

The generated queue report should list the slot storage names, enqueue pulse
source, generated update rules, generated assertions, concrete ID, depth, and
transaction order inventory.

For response demux, `.106` may report:

```yaml
response_demux:
  generated_behavior: true
  read:
    mode: bounded_read_rid_queue_head_demux_contract
    generated_behavior: true
    implementation_status: generated
    transaction_completion_source: generated_queue_head_demux
    transaction_completion_semantics: matched_concrete_id_queue_head_and_last_signal
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
```

For the covered sample, `response_demux.residue` should remove
`generated_same_id_queue_head_demux` and keep only residue that remains true,
such as `read_data_interleaving` and `bursts`. Broader generalized queue
coverage can remain residue under `same_id_ordering` until later owners.

## Validation Gates For `.106`

The implementation slice must include:

- syntax checks for touched Perl modules and focused tests;
- focused generator coverage for generated queue storage, queue transition
  rules, response-demux rules, generated completion outputs, assertions, and
  report movement;
- focused PPIF/CLI coverage for schedule JSON, generated `.isf`, generated
  `.fsm`, default HDL, `--verify-hdl`, check JSON, and semantic JSON for the
  public sample;
- fail-closed tests proving unsupported wider shapes remain selected-not-
  generated or rejected as selected by `.106`;
- support-accounting/doc updates if generated behavior changes corpus status;
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map sync;
- worker-process monitoring for long PPIF/HDL validation runs.

## Deferred Work

Still deferred after `.106` unless another owner explicitly ships it:

- write same-ID queue-head behavior;
- read `single-beat` concrete same-ID queue-head behavior;
- more than one duplicate concrete-ID group;
- groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head demux;
- read-data consumption of concrete same-ID queue-head demux;
- different-ID interleaving beyond the covered ID;
- generalized per-ID issue-order queues;
- direct backend lowering;
- VHDL.

## Rollback

Rollback for this selector is documentation-only. Rollback for the future
implementation should restore the `.103` selected-not-generated runtime
baseline: authored transaction completion inputs, admitted request pulses only,
no queue state, no queue-head demux rules, `accepted_same_id_reuse: false`, and
`generated_queue_behavior: false`.
