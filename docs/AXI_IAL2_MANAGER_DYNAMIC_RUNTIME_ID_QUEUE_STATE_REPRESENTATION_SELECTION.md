# AXI IAL2 Manager Dynamic Runtime-ID Queue-State Representation Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.454`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.454` selects the runtime-ID
queue-state representation for the first generated dynamic same-ID
`issue-order-queue` behavior and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.455`, implementation of the bounded
two-transaction all-dynamic write `BID` dynamic issue-order queue behavior.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read:

- `.453` generated dynamic queue public contract selection;
- `.452` generated dynamic queue readiness audit;
- `.450` metadata-first dynamic same-ID `issue-order-queue` behavior and
  `.449` source/report contract;
- generated dynamic write/read/read-burst-last response-demux, read-data,
  multi-beat, and recapture behavior records;
- generated dynamic same-ID `reject` mapping records from `.438`, `.442`,
  and `.446`;
- concrete same-ID admitted-request, compact queue-state, queue-head demux,
  write/read queue behavior, and counted admission records;
- current PPIF parser support, response-demux normalization/report code,
  concrete queue rule generation, dynamic demux rule generation, residue
  projection, support-accounting surfaces, public PPIF samples, and focused
  dynamic tests;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Selected Representation

The first generated dynamic queue representation is:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
runtime_id_queue_key: captured_request_id
first_generated_scope: write_bid_two_dynamic_transactions
```

For the first implementation, the selected public source shape is exactly two
write transactions, every selected write transaction uses `(id dynamic)`,
and explicit `response-demux.write` owns generated completion pulses:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id dynamic)))

(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The representation is a compact ordered vector of bounded slots. Each slot
stores:

- a one-hot-or-empty transaction identity bit for each selected dynamic write
  transaction;
- one slot-local captured runtime ID register, with the write ID-family width;
- a derived valid predicate equal to the OR of that slot's transaction bits.

For the first two-transaction implementation, storage should be equivalent to:

```text
axi0_write_dynamic_same_id_issue_order_slot0_w0_q
axi0_write_dynamic_same_id_issue_order_slot0_w1_q
axi0_write_dynamic_same_id_issue_order_slot0_id_q
axi0_write_dynamic_same_id_issue_order_slot1_w0_q
axi0_write_dynamic_same_id_issue_order_slot1_w1_q
axi0_write_dynamic_same_id_issue_order_slot1_id_q
```

The exact prefix may follow existing generator naming, but reports must expose
the transaction slot storage and captured-ID storage explicitly.

## Why This Representation

The existing concrete same-ID queue representation stores only transaction
identity because every group has a compile-time concrete ID. Dynamic queues
cannot copy that state directly; the response key is the runtime `BID`, and
the key for an outstanding entry is the request ID captured at admission.

The existing dynamic response-demux representation stores a selected ID per
transaction, but its multi-active form deliberately rejects active same-ID
overlap through no-active-same-ID and active-ID uniqueness assertions. Dynamic
`issue-order-queue` must allow two active entries with the same captured ID.

The selected compact slot representation keeps the lowerable parts of both
precedents without inheriting the wrong policy:

- it is finite and scalar, like the concrete queue slots;
- it stores captured runtime IDs explicitly, like dynamic demux selected-ID
  state;
- it does not require arrays, dynamic indexed left-hand sides, hidden
  unbounded allocation, modulo pointers, profile-global queue state, or
  direct-backend-only behavior;
- it preserves per-ID issue order by selecting the earliest matching slot for
  the response ID.

An explicit per-runtime-ID queue map or predecessor/age table is not selected
for the first implementation. It would require a dynamic key-indexed state
contract and broader capacity policy before the two-transaction write `BID`
case needs it.

## Predicates And Matching

For depth two:

```text
slot0_valid = slot0_w0 || slot0_w1
slot1_valid = slot1_w0 || slot1_w1
empty       = !slot0_valid
full        = slot0_valid && slot1_valid
compact     = slot1_valid -> slot0_valid
```

The response match is not a static queue-head match. It is the earliest valid
slot whose captured runtime ID equals the raw write response `BID`:

```text
slot0_raw_match = axi0_write_complete && slot0_valid
                  && (axi0_bid == slot0_id_q)
slot1_raw_match = axi0_write_complete && slot1_valid
                  && (axi0_bid == slot1_id_q)

slot0_selected_match = slot0_raw_match
slot1_selected_match = slot1_raw_match && !slot0_raw_match
```

If both slots hold the same captured ID, the response completes slot0. If
slot0 has a different ID and slot1 matches `BID`, the response may complete
slot1 while slot0 remains outstanding. This is the required per-ID ordering
behavior: same captured IDs are ordered, different captured IDs may complete
out of global issue order.

The generated completion for transaction `wN` is the selected match for the
slot containing `wN`.

## Enqueue, Dequeue, And Same-Cycle Policy

The enqueue source is a queue-owned admitted dynamic write request for each
selected transaction. Its guard is the transaction request event plus the
capacity/storage admission predicate, onehot0 selected dynamic write request
policy, and queue-specific space after any selected dequeue.

The first implementation supports at most one admitted write enqueue per
cycle:

```text
simultaneous_request_policy: onehot0_dynamic_issue_order_write_request
```

A same-cycle selected dequeue plus one enqueue is supported. The transition
removes the selected matching slot, compacts remaining entries toward slot0,
and appends the admitted transaction to the first free tail slot. The admitted
entry captures the current `AWID` from the write ID-family request ID source.

If an admitted request is for the same transaction that is selected for
dequeue in that cycle, the implementation treats it as release-and-recapture
through the queue transition: remove the old slot entry, then append the new
entry with the new captured `AWID`. The old response match is computed from
pre-update state; the new captured ID is next-cycle state.

If an admitted request names a transaction that remains in the queue after
the selected dequeue, the duplicate-transaction assertion fires. This
preserves one outstanding entry per transaction for the first implementation.

## Assertion Direction

The implementation owner must not reuse the reject-only active-ID uniqueness
or no-active-same-ID assertions as dynamic queue evidence. Those assertions
remain valid only for `dynamic-id-reuse reject` mappings and unsupported
queue shapes.

The first dynamic issue-order queue behavior should generate queue-specific
assertion roles:

- slot onehot0 for each slot;
- compact slot ordering;
- request onehot0 for selected dynamic write requests;
- enqueue requires queue space or a same-cycle selected dequeue;
- response requires at least one active slot with matching captured runtime ID;
- selected response match is onehot0;
- raw multi-match by captured ID is allowed and resolves to the earliest
  matching slot;
- selected dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after the selected dequeue;
- generated completion implies an active selected slot for that transaction.

The report should distinguish:

```text
same_id_overlap_policy: allowed_by_issue_order_queue
multi_match_policy: earliest_matching_slot
active_id_uniqueness_policy: not_required_for_issue_order_queue
```

from the reject-only `active_dynamic_ids_must_be_unique` vocabulary.

## Report Direction

The later `.455` implementation should move only the covered
two-transaction all-dynamic write `BID` shape to generated behavior. Candidate
schedule/check/semantic fields are:

```yaml
same_id_ordering:
  dynamic_id_reuse_policy:
    write:
      policy: issue_order_queue
      implementation_status: generated_dynamic_write_bid_issue_order_queue
      enforcement: generated_dynamic_issue_order_queue
      accepted_same_id_reuse: true
      generated_queue_behavior: true
      generated_scoreboard_behavior: false
      runtime_id_queue_key: captured_request_id
      queue_state_representation: compact_runtime_id_issue_order_slots
      response_demux_strategy: dynamic_issue_order_earliest_matching_slot
      first_generated_scope: write_bid_two_dynamic_transactions
      same_id_overlap_policy: allowed_by_issue_order_queue
      multi_match_policy: earliest_matching_slot
```

The response-demux report should use a new mode distinct from
`bounded_multi_dynamic_write_bid_demux_contract`, because completion no longer
depends on active-ID uniqueness:

```text
response_demux.write.mode:
  bounded_dynamic_write_bid_issue_order_queue_demux_contract
transaction_completion_source:
  generated_dynamic_issue_order_queue_demux
transaction_completion_semantics:
  earliest_matching_captured_runtime_id
```

Until `.455` ships, reports must preserve the current selected-not-generated
metadata:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
dynamic_per_id_issue_order_queues residue
```

## Preservation Matrix

`.455` and later owners must preserve:

- metadata-first dynamic issue-order queue behavior from `.450`;
- generated dynamic `reject` mappings from `.438`, `.442`, and `.446`;
- generated dynamic response-demux/read-data/burst/runtime/multi-beat and
  recapture behavior for reject and unique-ID shapes;
- concrete same-ID queue-head behavior, counted admission, read-data, and
  report contracts;
- current fail-closed behavior for dynamic queue shapes outside the exact
  two-transaction all-dynamic write `BID` owner;
- support-accounting identities and existing public PPIF samples until `.455`
  intentionally adds the new generated sample;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement parser, generator, PPIF sample, support-accounting, test,
  schedule/check/semantic JSON, HDL, or runtime behavior in `.454`.
- Do not accept generated dynamic queue behavior or accepted dynamic same-ID
  reuse in `.454`.
- Do not select read, read-data, burst-last, mixed dynamic/static, static
  concrete, auto-ID, scoreboard, direct backend, backend-language variant, or
  VHDL behavior as the first dynamic queue implementation.
- Do not introduce dynamic-indexed arrays, modulo pointers, unbounded
  allocation, or direct-backend-only queue state.
- Do not reinterpret generated dynamic `reject` mappings as queue behavior.

## Validation For `.454`

Because `.454` is a representation-selection slice, validation is
documentation and continuity focused:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No Perl, `prove`, `fsmgen`, HDL, schedule/check/semantic JSON, or generated
artifact behavior is expected to change in this slice.

## Rollback

Rollback for `.454` is this docs-only representation-selection commit.
Reverting it removes the `.455` selection, fact card, task-tree advancement,
live-doc updates, and resume pointer update without changing generated
behavior.
