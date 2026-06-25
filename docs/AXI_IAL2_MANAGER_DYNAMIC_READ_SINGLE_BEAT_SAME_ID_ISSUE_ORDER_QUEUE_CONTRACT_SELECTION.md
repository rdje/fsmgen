# AXI IAL2 Manager Dynamic Read Single-Beat Same-ID Issue-Order Queue Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.458`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.458` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.459`, implementation of the first
generated dynamic read same-ID `issue-order-queue` behavior.

The selected public contract is deliberately narrow:

- exactly two read transactions;
- both selected read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.read` owns generated single-beat `RID`
  completions;
- `response-demux.read.response-scope` is `single-beat`;
- `read-max-pending` is at least `2`;
- read auto-ID lifecycle metadata, static/concrete same-family reads,
  read-data, burst metadata, `last_signal`, raw `ARLEN`, runtime
  beat-count/`RLAST`, multi-beat output banks, and scoreboard policy are
  absent.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, focused test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read the `.457` readiness audit, `.456` post-write selector,
`.455` generated dynamic write queue behavior, `.454` runtime-ID
representation selection, `.453` generated dynamic queue contract selection,
`.452` readiness audit, `.450` metadata-first dynamic issue-order policy
behavior, existing generated dynamic read single-beat `RID` response-demux and
recapture records, multiple all-dynamic read single-beat demux and recapture
records, generated dynamic same-ID `reject` mapping records, concrete read
single-beat queue-head behavior, current parser/report/residue/sample/
support-accounting/code/test surfaces, README, ROADMAP_V2, mdBook, MEMORY,
task tree, and Knowledge Map facts.

## Selected Public Shape

`.459` should add a new support-accounted public sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif
```

The intended source shape is:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id dynamic)))

(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family must provide the runtime request and response ID signals,
for example:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The sample support-accounting identity should be:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_pipeline_cli
```

## Generated Queue Contract

The read queue should reuse the `.454`/`.455` dynamic queue representation
with read-family signals:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
first_generated_scope: read_rid_two_dynamic_transactions
```

The generated storage should be equivalent to:

```text
axi0_read_dynamic_same_id_issue_order_slot0_r0_q
axi0_read_dynamic_same_id_issue_order_slot0_r1_q
axi0_read_dynamic_same_id_issue_order_slot0_id_q
axi0_read_dynamic_same_id_issue_order_slot1_r0_q
axi0_read_dynamic_same_id_issue_order_slot1_r1_q
axi0_read_dynamic_same_id_issue_order_slot1_id_q
```

Each slot stores one-hot-or-empty transaction identity and one slot-local
captured `ARID`. The response key is raw `RID` from the read ID family.

Raw response matching selects the earliest valid slot whose captured runtime ID
equals `axi0_rid`:

```text
slot0_raw_match = axi0_read_complete && slot0_valid && axi0_rid == slot0_id_q
slot1_raw_match = axi0_read_complete && slot1_valid && axi0_rid == slot1_id_q

slot0_selected_match = slot0_raw_match
slot1_selected_match = slot1_raw_match && !slot0_raw_match
```

If both slots hold the same captured `ARID`, slot0 completes first. If slot0
holds a different ID and slot1 matches `RID`, slot1 may complete while slot0
remains outstanding. That preserves AXI per-ID ordering without imposing a
global completion order.

## Enqueue And Dequeue Policy

The enqueue source is the queue-owned admitted dynamic read request for each
selected transaction. The first implementation must admit at most one queued
read request per cycle:

```text
request_conflict_policy: generated_issue_order_queue_onehot0_enqueue
```

A same-cycle selected dequeue plus one enqueue is part of the selected
contract. The selected match is computed from pre-update queue state. The
transition removes the selected slot, compacts retained entries toward slot0,
and appends the admitted transaction with the current `ARID` as next-cycle
captured state.

If the admitted request is for the same transaction being selected for
dequeue, the queue transition performs release-and-recapture by removing the
old slot entry and appending the new entry. If the admitted request names a
transaction still present after selected dequeue, the duplicate-transaction
assertion must fire.

## Report Contract

The generated read response-demux report should use:

```yaml
response_demux:
  read:
    mode: bounded_dynamic_read_rid_issue_order_queue_demux_contract
    generated_behavior: true
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    transaction_completion_source: generated_dynamic_issue_order_queue_demux
    transaction_completion_semantics: earliest_matching_captured_runtime_id
    queue_state_representation: compact_runtime_id_issue_order_slots
    runtime_id_queue_key: captured_request_id
    response_demux_strategy: dynamic_issue_order_earliest_matching_slot
    dynamic_transactions: [r0, r1]
```

The same-ID ordering read policy should report:

```yaml
same_id_ordering:
  dynamic_id_reuse_policy:
    read:
      policy: issue_order_queue
      implementation_status: generated_dynamic_read_rid_issue_order_queue
      enforcement: generated_dynamic_issue_order_queue
      assertion_enforcement: runtime_assertion
      accepted_same_id_reuse: true
      generated_queue_behavior: true
      generated_scoreboard_behavior: false
      response_demux_covered: true
      dynamic_issue_order_queue_covered: true
      queue_state_representation: compact_runtime_id_issue_order_slots
      runtime_id_queue_key: captured_request_id
      response_demux_strategy: dynamic_issue_order_earliest_matching_slot
      same_id_overlap_policy: allowed_by_issue_order_queue
      multi_match_policy: earliest_matching_slot
      active_id_uniqueness_policy: not_required_for_issue_order_queue
      request_conflict_policy: generated_issue_order_queue_onehot0_enqueue
      first_generated_scope: read_rid_two_dynamic_transactions
      covered_dynamic_transactions: [r0, r1]
```

For the covered source, `response_demux.residue` should remove
`same_id_ordering` but continue to expose `read_data_interleaving` and
`bursts`. Same-ID ordering residue should remove the covered dynamic read
same-ID queue residue.

## Assertion Contract

`.459` must use queue-specific assertions, not reject-only active-ID
uniqueness assertions. Required assertion roles are:

- slot onehot0 checks for both slots;
- compact slot ordering;
- onehot0 admitted read-request policy;
- enqueue requires queue space or same-cycle selected dequeue;
- response requires a nonempty queue;
- response has a selected captured-ID match;
- selected response match is onehot0;
- selected dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- admitted transaction is not already present after selected dequeue; and
- each generated transaction completion follows the selected runtime-ID match.

Reject-only `active_dynamic_ids_must_be_unique`,
`*_dynamic_request_no_active_same_id`, and pairwise active-ID uniqueness
assertions remain evidence only for `dynamic-id-reuse reject` mappings and for
non-queue demux shapes that intentionally require unique active IDs.

## Implementation Boundary

`.459` should implement the exact public shape above. A reasonable code shape
is a read sibling of the current write-only dynamic queue plan:

- plan `response-demux.read` dynamic issue-order queues before the existing
  fail-closed read dynamic-policy diagnostic;
- require exactly two all-dynamic read transactions, shared read ID-family
  request source, `read-max-pending >= 2`, no read auto-ID lifecycle, and
  explicit generated single-beat read response-demux;
- reuse the existing dynamic queue transition, compaction, captured-ID
  assignment, earliest-match, and assertion helpers with `family => read`;
- keep the existing write queue behavior and all reject/mixed/static/concrete
  queue behavior unchanged;
- add focused parser/adapter/generator/dynamic/support-accounting coverage,
  schedule/check/semantic JSON probes, generated SystemVerilog inspection, and
  docs/Knowledge Map updates.

## Deferred Work

These remain future exact owners:

- dynamic read burst-last `RID && RLAST` issue-order queues;
- read-data over generated dynamic read queues;
- raw `ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank behavior
  over generated dynamic read queues;
- dynamic queue cardinality beyond exactly two all-dynamic reads;
- mixed dynamic/static same-ID queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

This contract-selection slice is documentation/task-tree only. Closeout gates
should cover Knowledge Map regeneration/check, mdBook build, docs
relative-path audit, memory-architecture check, diff hygiene, and the full
doctrine gate.

Runtime Perl, PPIF, schedule/check/semantic JSON, generated HDL, focused
tests, and broad `prove` gates are not required for `.458` because no parser
or generated behavior changed. They are required in `.459`.

## Rollback

Rollback is the `.458` selector commit. Reverting it removes this contract
record, the new fact card/map entry, README/ROADMAP/mdBook wording, task-tree
frontier movement, and MEMORY pointer update, restoring `.458` as the active
contract-selection owner after the `.457` readiness audit.
