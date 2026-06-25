# AXI IAL2 Manager Generated Dynamic Same-ID Issue-Order Queue Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.453`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.453` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.454`, runtime-ID queue-state
representation selection for the first generated dynamic same-ID
`issue-order-queue` behavior.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read:

- `.452` generated dynamic issue-order queue readiness audit;
- `.451` post metadata selector, `.450` metadata-first dynamic same-ID
  `issue-order-queue` behavior, and `.449` dynamic issue-order policy
  contract;
- `.448`, `.446`, `.442`, `.438`, `.436`, `.434`, `.217`, `.223`, `.227`,
  `.231`, `.247`, `.251`, `.255`, `.259`, `.268`, `.341`, `.347`, `.375`,
  and related generated dynamic response-demux/read-data/multi-beat/
  recapture records;
- concrete same-ID `issue-order-queue` contract, admitted-request pulse,
  compact queue-state, queue-head response-demux, write/read generated
  behavior, and group-local/counted admission records;
- PPIF parser support for `dynamic-id-reuse issue-order-queue`;
- current generator normalization/report code for dynamic same-ID policies,
  dynamic response-demux composition, concrete queue-state behavior,
  report/residue projection, and support detail;
- public dynamic and concrete queue PPIF samples and support-accounting
  surfaces;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Current Public Boundary

The public source spelling already exists as metadata:

```lisp
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
```

and reports:

```text
policy: issue_order_queue
implementation_status: selected_not_generated
enforcement: not_generated
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
residue: dynamic_per_id_issue_order_queues
```

The generated dynamic response-demux path still accepts same-family
`same-id-ordering` only for `dynamic-id-reuse reject`. A source that combines
dynamic write response-demux with `dynamic-id-reuse issue-order-queue` still
fails closed before generated behavior, which is the correct rollback
baseline.

## Selected First Behavior Family

The first generated dynamic issue-order queue path should start with the write
`BID` family, not read `RID`, read `RID && RLAST`, read-data, mixed
dynamic/static, direct backend, or VHDL.

The target public source shape after the representation prerequisite is:

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

The first behavior contract should be all-dynamic and write-only:

- exactly one selected response family: `write`;
- two or more write transactions, with the first implementation expected to
  prove the two-transaction public sample before widening;
- every selected write transaction uses `(id dynamic)`;
- no same-family static concrete transactions, auto-ID lifecycle,
  concrete queue-head behavior, read-data, burst metadata, or scoreboard
  policy;
- explicit `response-demux.write` remains required;
- generated transaction completions remain pulse outputs owned by the
  generated demux/queue behavior.

Read single-beat, read burst-last, read-data, multi-beat, mixed
dynamic/static, broader cardinality, and same-family dynamic plus static
queue behavior must remain later exact owners.

## Why A Representation Prerequisite

Direct generated behavior is still too broad. The first implementation would
otherwise need to settle source composition, runtime-ID keying, queue state,
admitted enqueue, dequeue, response matching, same-cycle policy,
overflow/ambiguity assertions, report fields, residue movement, tests, and
HDL in one slice.

Concrete queue state cannot be copied directly. Concrete queue groups are
static `(family, concrete ID value)` groups. Dynamic issue-order queues must
choose a representation for a queue whose key is the request ID captured at
admission time and whose response key is the runtime `BID`.

The existing multiple dynamic demux state also cannot be reused unchanged. It
proves `dynamic-id-reuse reject` through:

```text
same_id_conflict_policy: active_dynamic_ids_must_be_unique
simultaneous_request_policy: onehot0_dynamic_write_request
```

An issue-order queue must allow multiple active dynamic transactions with the
same captured runtime ID, so the no-active-same-ID and active-ID uniqueness
assertions are reject-only evidence. They must be replaced, preserved only for
unsupported policies, or moved into new overflow/ambiguity checks selected by
the representation owner.

## `.454` Representation Questions

`.454` must select the generated representation before implementation. It
should decide:

- whether the runtime-ID queue key is represented by per-transaction captured
  request-ID state, slot-local captured-ID state, or another bounded scalar
  shape;
- whether the queue stores global issue order with response-time runtime-ID
  filtering, explicit per-runtime-ID predecessor/age state, or another
  signoff-lowerable equivalent;
- the queue-entry state vocabulary, including transaction identity,
  captured-ID association, busy/valid bits, depth, full, empty, and selected
  head predicates;
- how the first two-transaction write `BID` queue avoids arrays, dynamic
  indexed left-hand sides, hidden unbounded allocation, profile-global queue
  state, modulo pointers, or direct-backend-only behavior;
- which current dynamic selected-ID and busy state can be reused and which
  state must be new queue-owned state;
- how admitted dynamic write requests enqueue when the queue is full,
  releasing, or same-cycle dequeuing;
- whether the first behavior supports same-cycle dequeue plus enqueue, fails
  closed with assertions, or splits release-and-recapture into a later owner;
- how a raw `BID` response selects the earliest queued active transaction
  whose captured runtime ID equals `BID`;
- overflow, duplicate active transaction, empty response, inactive response,
  no-match, multi-match, and ambiguous-response assertion roles;
- report fields and residue movement for representation-only, selected
  not-generated, and later generated behavior states.

## Report Direction

Until generated dynamic queue behavior ships, reports must preserve:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
generated_scoreboard_behavior: false
dynamic_per_id_issue_order_queues residue
```

The later generated write behavior should use a distinct dynamic queue
vocabulary, not the concrete `concrete_id_reuse_policy` fields and not the
dynamic reject mapping fields. Candidate fields that `.454` should confirm or
replace include:

```text
same_id_ordering.dynamic_id_reuse_policy.write.enforcement:
  generated_dynamic_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.implementation_status:
  generated_dynamic_write_bid_issue_order_queue
same_id_ordering.dynamic_id_reuse_policy.write.accepted_same_id_reuse: true
same_id_ordering.dynamic_id_reuse_policy.write.generated_queue_behavior: true
same_id_ordering.dynamic_id_reuse_policy.write.runtime_id_queue_key:
  captured_request_id
same_id_ordering.dynamic_id_reuse_policy.write.queue_state_representation:
  <selected-by-.454>
same_id_ordering.dynamic_id_reuse_policy.write.response_demux_strategy:
  dynamic_issue_order_queue_head
```

The response-demux report should use a new mode or boundary distinct from
`bounded_multi_dynamic_write_bid_demux_contract`, because the generated match
is no longer "active unique dynamic ID" matching. The later covered source may
remove `same_id_ordering` from `response_demux.residue` only when generated
dynamic queue demux owns the selected write family.

## Preservation Matrix

`.454` and later implementation owners must preserve:

- metadata-first dynamic issue-order queue behavior from `.450`;
- generated dynamic `reject` mappings from `.438`, `.442`, and `.446`;
- generated dynamic write/read/read-burst-last response-demux, read-data,
  burst-length/runtime, multi-beat, and recapture behavior for reject/unique-ID
  shapes;
- concrete same-ID queue-head behavior, counted admission, read-data, and
  report contracts;
- current fail-closed behavior for dynamic issue-order queue plus
  response-demux until the exact generated behavior owner intentionally
  changes it;
- support-accounting identities and public PPIF sample identities until the
  implementation owner adds a new sample;
- direct backend deferral, VHDL deferral, and backend-language neutrality.

## Non-Goals

- Do not implement parser, generator, PPIF sample, support-accounting, test,
  schedule/check/semantic JSON, HDL, or runtime behavior in `.453`.
- Do not accept generated dynamic queue behavior or accepted dynamic same-ID
  reuse in `.453`.
- Do not select read, read-data, mixed dynamic/static, scoreboard, direct
  backend, backend-language variant, or VHDL behavior as the first dynamic
  queue implementation.
- Do not reinterpret generated dynamic `reject` mappings as queue behavior.
- Do not change concrete queue behavior or current dynamic response-demux
  uniqueness contracts.

## Validation For `.453`

Because `.453` is a contract-selection slice, validation is documentation and
continuity focused:

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

Rollback for `.453` is this docs-only contract-selection commit. Reverting it
removes the `.454` selection, fact card, task-tree advancement, live-doc
updates, and resume pointer update without changing generated behavior.
