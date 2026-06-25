# AXI IAL2 Manager Dynamic Read Burst-Last Same-ID Issue-Order Queue Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.462`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.462` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.463`, direct implementation of the first
generated dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior.

The selected public contract is deliberately narrow:

- exactly two read transactions;
- both selected read transactions use `(id dynamic)`;
- `same-id-ordering.read` selects `(dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.read` owns generated burst-last `RID && RLAST`
  completions;
- `response-demux.read.response-scope` is `burst-last`;
- `response-demux.read.last-signal` names a one-bit `RLAST` signal;
- `read-max-pending` is at least `2`;
- read auto-ID lifecycle metadata, static/concrete same-family reads,
  read-data, raw `ARLEN`, runtime beat-count/`RLAST`, multi-beat output
  banks, mixed dynamic/static read queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL are outside this owner.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read the `.461` readiness audit, `.460` selector, `.459`
generated dynamic read single-beat queue behavior, `.458` contract selection,
`.457` readiness audit, `.455` generated dynamic write queue behavior, `.454`
runtime-ID queue-state representation selection, generated dynamic read
burst-last response-demux/read-data/raw `ARLEN`/runtime/multi-beat/recapture
records, concrete read burst-last queue-head readiness and behavior records,
current parser, response-demux normalization, queue-state builder, assertion,
read-data coverage, support-accounting, focused-test, README, ROADMAP_V2,
mdBook, MEMORY, task tree, and Knowledge Map surfaces.

## Selected Public Shape

`.463` should add a new support-accounted public sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif
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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family must provide the runtime request and response ID signals:

```lisp
(id-families
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The sample support-accounting identity should be:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_pipeline_cli
```

## Generated Queue Contract

The burst-last read queue reuses the `.454` compact runtime-ID slot
representation with read-family signals:

```text
queue_state_representation: compact_runtime_id_issue_order_slots
runtime_id_queue_key: captured_request_id
response_demux_strategy: dynamic_issue_order_earliest_matching_slot
first_generated_scope: read_rid_rlast_two_dynamic_transactions
```

The generated storage should stay equivalent to the shipped single-beat read
queue:

```text
axi0_read_dynamic_same_id_issue_order_slot0_r0_q
axi0_read_dynamic_same_id_issue_order_slot0_r1_q
axi0_read_dynamic_same_id_issue_order_slot0_id_q
axi0_read_dynamic_same_id_issue_order_slot1_r0_q
axi0_read_dynamic_same_id_issue_order_slot1_r1_q
axi0_read_dynamic_same_id_issue_order_slot1_id_q
```

Each slot stores one-hot-or-empty transaction identity and one slot-local
captured `ARID`. The response key is raw `RID`; `RLAST` selects completion and
dequeue, not active-beat ownership.

Raw response matching must remain last-agnostic:

```text
slot0_raw_match = response_event && slot0_valid && axi0_rid == slot0_id_q
slot1_raw_match = response_event && slot1_valid && axi0_rid == slot1_id_q

slot0_selected_raw_match = slot0_raw_match
slot1_selected_raw_match = slot1_raw_match && !slot0_raw_match
```

Final selected matching adds `RLAST`:

```text
slot0_selected_final_match = slot0_selected_raw_match && axi0_rlast
slot1_selected_final_match = slot1_selected_raw_match && axi0_rlast
```

If both slots hold the same captured `ARID`, slot0 completes first on the
first matching final beat. If slot0 holds a different ID and slot1 matches
`RID && RLAST`, slot1 may complete while slot0 remains outstanding. Non-final
matching beats are legal raw beats, must match at least one active captured
runtime ID, and must not dequeue or pulse a generated transaction completion.

## Enqueue And Dequeue Policy

The enqueue source remains the queue-owned admitted dynamic read request for
each selected transaction. The first implementation must admit at most one
queued read request per cycle:

```text
request_conflict_policy: generated_issue_order_queue_onehot0_enqueue
```

The selected dequeue condition is the selected final match:

```text
selected_dequeue = selected_raw_match && axi0_rlast
```

A same-cycle selected final dequeue plus one enqueue is part of the selected
contract. The selected match is computed from pre-update queue state. The
transition removes the selected slot, compacts retained entries toward slot0,
and appends the admitted transaction with the current `ARID` as next-cycle
captured state.

If the admitted request is for the same transaction being selected for final
dequeue, the queue transition performs release-and-recapture by removing the
old slot entry and appending the new entry. If the admitted request names a
transaction still present after selected final dequeue, the
duplicate-transaction assertion must fire.

## Report Contract

The generated read response-demux report should use:

```yaml
response_demux:
  read:
    mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
    generated_behavior: true
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    last_signal: axi0_rlast
    last_signal_width: 1
    transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
    transaction_completion_semantics: earliest_matching_captured_runtime_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
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
      implementation_status: generated_dynamic_read_rid_rlast_issue_order_queue
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
      first_generated_scope: read_rid_rlast_two_dynamic_transactions
      covered_dynamic_transactions: [r0, r1]
```

Covered transactions should continue to report ID matching as:

```text
generated_issue_order_queue_matching
```

For the covered source, `response_demux.residue` should remove
`same_id_ordering` but continue to expose `read_data_interleaving` and
`bursts`. Same-ID ordering residue should remove the covered dynamic read
same-ID queue residue. A later read-data owner may consume this response-demux
source using the reserved completion-validity string:

```text
generated_dynamic_issue_order_queue_read_response_demux_last_beat_completion_pulse
```

`.463` must not wire that read-data coverage yet.

## Assertion Contract

`.463` must use queue-specific assertions, not reject-only active-ID
uniqueness assertions. Required assertion roles are:

- slot onehot0 checks for both slots;
- compact slot ordering;
- onehot0 admitted read-request policy;
- enqueue requires queue space or same-cycle selected final dequeue;
- raw response requires a nonempty queue;
- raw response must match at least one captured runtime ID;
- selected raw response match is onehot0 after earliest-slot selection;
- non-final matching response beats do not dequeue;
- selected final dequeue requires a nonempty queue;
- each transaction appears in at most one slot;
- an admitted transaction is not already present after selected final
  dequeue; and
- each generated transaction completion follows the selected final
  runtime-ID-and-`RLAST` match.

Reject-only `active_dynamic_ids_must_be_unique`,
`*_dynamic_request_no_active_same_id`, and pairwise active-ID uniqueness
assertions remain evidence only for `dynamic-id-reuse reject` mappings and for
non-queue demux shapes that intentionally require unique active IDs.

## Implementation Boundary

`.463` should implement only the exact public shape above. A reasonable code
shape is a burst-last sibling of the shipped read single-beat dynamic queue
path:

- allow the dynamic read issue-order queue response-demux plan only for
  `response-scope burst-last` plus one-bit `last-signal`;
- keep exactly two all-dynamic reads, shared read ID-family request source,
  `read-max-pending >= 2`, no read auto-ID lifecycle, and explicit generated
  read response-demux requirements;
- carry `last_signal` into the dynamic queue group;
- split raw selected match from final selected match so non-final beats are
  checked but not dequeued;
- emit generated completions only for selected final matches;
- add the dynamic queue non-last no-dequeue assertion role;
- keep read-data, raw `ARLEN`, runtime beat-count/`RLAST`, multi-beat output
  banks, recapture widening, broader cardinality, mixed dynamic/static queues,
  scoreboards, direct backend behavior, backend-language variants, and VHDL
  fail-closed.

## Diagnostics And Preservation

Until `.463` ships, the existing diagnostic remains correct:

```text
response_demux.read dynamic-id-reuse issue-order-queue supports only
response_scope single-beat in this slice
```

`.463` may relax that diagnostic only for the selected shape. All other
dynamic read issue-order queue shapes should remain fail-closed, including:

- missing `last-signal` or non-one-bit `last-signal` for burst-last scope;
- `last-signal` on single-beat scope;
- fewer or more than two all-dynamic read transactions;
- mixed dynamic/static or concrete same-family read transactions;
- missing shared read ID-family request/response ID metadata;
- `read-max-pending < 2`;
- read auto-ID lifecycle metadata;
- read-data, raw `ARLEN`, runtime, multi-beat, or recapture consumers over the
  new queue completion source in the same behavior slice.

The implementation must preserve generated dynamic `reject` mappings,
single-active and multiple dynamic read `RID`/`RID && RLAST` response-demux,
dynamic read-data/raw-`ARLEN`/runtime/multi-beat consumers over non-queue
demux sources, shipped dynamic read/write queue behavior, concrete same-ID
queue-head behavior, public support-accounting identities, direct-backend
deferral, backend-language neutrality, and VHDL deferral.

## Deferred Work

These remain future exact owners:

- read-data over generated dynamic read queues;
- raw `ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank behavior
  over generated dynamic read queues;
- same-cycle recapture widening over generated dynamic read burst-last queues
  after the queue completion source exists;
- dynamic queue cardinality beyond exactly two all-dynamic reads;
- mixed dynamic/static same-ID queues;
- dynamic scoreboards;
- validation and memory retry follow-up;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

This contract-selection slice is documentation/task-tree only. Closeout gates
should cover Knowledge Map regeneration/check, mdBook build, docs
relative-path audit, memory-architecture check, diff hygiene, and the full
doctrine gate.

Runtime Perl, PPIF, schedule/check/semantic JSON, generated HDL, focused
tests, and broad `prove` gates are not required for `.462` because no parser
or generated behavior changed. They are required in `.463`.

## Rollback

Rollback is the `.462` selector commit. Reverting it removes this contract
record, the new fact card/map entry, README/ROADMAP/mdBook wording,
task-tree frontier movement, and MEMORY pointer update, restoring `.462` as
the active contract-selection owner after the `.461` readiness audit.
