# AXI IAL2 Manager Same-ID Issue-Order Queue Behavior Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`

Date: 2026-06-14

## Purpose

This audit decides whether the AXI same-ID `issue-order-queue` contract
selected by `.94` can move directly to generated queue-head behavior, can ship
as parser/report metadata first, or needs a smaller prerequisite before any
behavior changes.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, samples, support accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`
- generated write/read response-demux readiness notes
- current PPIF `same-id-ordering` parser behavior in
  `perl/FSM/Adapter/IAL2/PPIF.pm`
- current response-demux, same-ID policy, ID/response, rule, storage, and
  report behavior in `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- current IAL1 rule, pulse, scalar storage, and bank substrate in the mdBook,
  ISF spec, and focused tests
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
  - `ppif/axi_manager_capacity_status_response_demux.ppif`
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Current Behavior Boundary

The current PPIF parser accepts only:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject)))
```

`issue-order-queue` and `scoreboard` still fail closed at parse/normalization
time. The reject policy reports `generated_queue_behavior: false` and keeps
same-ID concrete ordering plus per-ID issue-order queues as residue.

Generated response demux is auto-ID-oriented. Normalization requires
`auto_id_lifecycle` metadata and selected auto transactions. Generated rules
iterate over auto-ID transaction states and use:

```text
raw_response_event && transaction_busy && response_id == selected_id
```

with `RLAST` added for burst-last read completion. That rule shape is correct
for generated auto-ID allocation and same-ID avoidance. It is not queue-head
demux for authored concrete transactions that intentionally share one ID.

Concrete-ID transactions currently live in the ID/response rule engine as
request/response ID assertions. When two same-family concrete transactions use
the same ID value, `_build_id_response_rule_engine` rejects them. Explicit
`reject` policy changes the diagnostic, but no current policy path accepts the
duplicate concrete ID set.

Transaction event dispatch records per-transaction request and completion
events, and the capacity/status rule matrix consumes per-direction fan-in. It
does not expose a per-transaction admitted-request pulse. Queue enqueue cannot
blindly use the raw request event, because the `.94` contract requires enqueue
on admitted transaction request only.

The lower layers can carry scalar storage, actor-owned banks, guarded rules,
one-cycle rule pulses, and assertions. The missing pieces are in the AXI
manager generator contract and helpers: admitted per-transaction enqueue
guards, concrete transaction in-flight/queue state, queue-head response-demux
rule emission, and queue-specific report/residue movement.

## Readiness Conclusion

Do not implement generated queue-head behavior directly in the next slice.
That would combine at least four new behavior families:

- parser acceptance for `issue-order-queue`;
- concrete same-ID duplicate validation changes;
- bounded per-ID queue state and enqueue/dequeue rule emission;
- queue-head response-demux and assertion/report residue movement.

That is too broad for signoff-level review.

It is safe to ship parser/report metadata first, provided the implementation
keeps fail-closed behavior for duplicated concrete same-ID transactions. The
metadata slice may accept the selected spelling and report it as
`selected_not_generated`, but it must not accept authored same-ID reuse or
emit generated queue behavior.

The safe metadata boundary is:

```text
same_id_ordering.concrete_id_reuse_policy.<family>.policy: issue_order_queue
same_id_ordering.concrete_id_reuse_policy.<family>.accepted_same_id_reuse: false
same_id_ordering.concrete_id_reuse_policy.<family>.generated_queue_behavior: false
same_id_ordering.concrete_id_reuse_policy.<family>.implementation_status: selected_not_generated
```

For a source that selects `issue-order-queue` and reuses one concrete ID in
the selected family, the implementation must still fail closed with a
specific diagnostic explaining that generated issue-order queue behavior is
not implemented yet.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`:

```text
Implement AXI same-ID issue-order queue parser/report metadata.
```

The implementation should:

- accept `issue-order-queue` as a `concrete-id-reuse` value in the existing
  read/write `same-id-ordering` family arms;
- normalize the report spelling to `issue_order_queue`;
- report `implementation_status: selected_not_generated`,
  `accepted_same_id_reuse: false`, and `generated_queue_behavior: false`;
- preserve explicit `reject` behavior unchanged;
- keep `scoreboard` unsupported;
- keep duplicated concrete-ID same-family transactions fail-closed under
  `issue-order-queue` until generated queue-head behavior ships;
- add a sample that selects `issue-order-queue` without claiming accepted
  duplicate same-ID reuse;
- keep generated `.isf`, `.fsm`, and SystemVerilog behavior unchanged for
  valid metadata-only sources.

## Later Generated Behavior Prerequisites

After metadata ships, a behavior-readiness or implementation owner must still
select or implement:

- an admitted per-transaction request enqueue guard;
- concrete transaction in-flight/queue identity state;
- per-family, per-ID queue depth derivation and generated storage naming;
- queue empty/count/head/tail or equivalent bounded shift-state helpers;
- enqueue/dequeue rules, including same-cycle enqueue/dequeue policy;
- queue-head response-demux rules for write, read single-beat, and
  read burst-last/multi-beat completion;
- overflow, underflow, empty-response, inactive-response, and ambiguous
  completion assertions;
- report artifacts for generated queue state, generated rules, generated
  assertions, and honest residue movement.

These remain on the SystemVerilog-backed `IAL2 -> IAL1 -> IAL0` path. Direct
backend lowering and VHDL remain deferred.

## Why Not Generated Queue Behavior Now

The current response-demux implementation derives transaction states from
`auto_id_lifecycle` and matches `response_id == selected_id`. Concrete
same-ID issue-order queues need a different owner: the response ID chooses
the concrete per-ID queue, and the queue head chooses the transaction.

The current capacity/status matrix also has direction-level fan-in but no
named per-transaction admitted-request event. Enqueueing on raw request events
would violate the `.94` contract when capacity blocks a request.

## Why Metadata First Is Safe

Metadata first is safe because it does not accept duplicated concrete same-ID
transactions. It only records the selected policy and leaves behavior residue
explicit. The generated artifacts remain unchanged, and the user-visible
report makes clear that implementation is not generated yet.

## Validation For This Audit

Audit gates:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_reject_policy.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This audit changes no behavior. If `.96` cannot keep metadata-only
`issue-order-queue` fail-closed for duplicated concrete same-ID reuse, it must
select a smaller parser/report prerequisite before any source value is
accepted.
