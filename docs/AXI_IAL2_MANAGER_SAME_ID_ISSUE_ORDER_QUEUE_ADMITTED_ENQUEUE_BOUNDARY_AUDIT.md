# AXI IAL2 Manager Same-ID Issue-Order Queue Admitted Enqueue Boundary Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.97`

Date: 2026-06-14

## Purpose

This audit decides the next safe prerequisite after `.96` shipped
metadata-first support for AXI same-ID `issue-order-queue`. The selected
contract requires enqueueing transaction identity only when a transaction
request is admitted, so this audit focuses on the admitted request boundary
before any queue state, queue-head response demux, or accepted same-ID reuse
behavior changes.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, samples, support accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`
- generated write/read response-demux behavior notes
- current transaction-event dispatch, ID/response, same-ID, response-demux,
  IAL1 emission, rule-matrix, and report code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- current IAL1 rule-pulse and storage substrate in the mdBook, ISF spec, and
  focused tests
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
  - `ppif/axi_manager_capacity_status_response_demux.ppif`
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Current Behavior Boundary

`.96` accepts the source spelling:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)))
```

and reports it honestly as selected but not generated:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: not_generated
      implementation_status: selected_not_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Duplicated concrete same-ID transactions still fail closed under the selected
policy. That remains correct until generated queue-head behavior exists.

Transaction event dispatch currently records per-transaction request and
completion events, then collapses each direction/phase into fan-in
expressions:

```yaml
transaction_event_dispatch:
  mode: per_transaction_event_fanin
  directions:
    - direction: read
      request_events: [axi0_r0_request]
      completion_events: [axi0_r0_complete]
      request_fanin: axi0_r0_request
      completion_fanin: axi0_r0_complete
```

For a multi-transaction direction the request fan-in is an OR expression such
as `(| axi0_w0_request axi0_w1_request)`. That is enough for the current
capacity/status counter because the rule matrix counts at most one accepted
direction-level submit per cycle. It is not enough to enqueue a concrete
transaction identity, because the queue must know which transaction was
admitted.

The current capacity/status matrix computes acceptance inside direction-level
occupancy rules. It emits `can_accept` as a status output, but that status is
not a named per-transaction admission event. Queue enqueue also must not read
the generated `can_accept` output as if it were a combinational source of
truth; the future enqueue guard must be derived from the same underlying
capacity state and same-cycle completion condition that the rule matrix uses.

Current generated response demux is also not the next prerequisite. It is
auto-ID-state based:

```text
raw_response_event && transaction_busy && response_id == selected_id
```

Concrete same-ID issue-order queues need the response ID to choose the per-ID
queue and the queue head to choose the transaction. That requires queue state
and cannot be selected before the admitted enqueue boundary is explicit.

## Substrate That Already Fits

The lower layers already have the pieces needed for a bounded admitted-request
prerequisite:

- per-transaction request event names are structural metadata;
- read/write pending counters and max-pending bounds already exist;
- rule guards can use boolean expressions and capacity-state comparisons;
- rule-owned `(pulse TARGET)` actions lower as one-cycle pulse-domain
  assignments;
- pulse targets may be scalar actor outputs or scalar actor storage variables;
- assertions already lower through the existing `+assert` path.

No IAL0 or SystemVerilog backend prerequisite is required for the admitted
request boundary itself.

## Missing Boundary

Generated queue behavior needs a named per-transaction admission point:

```text
transaction_request && direction_can_admit_this_cycle
```

where `direction_can_admit_this_cycle` is derived from current pending
occupancy, the family `max-pending` bound, and same-cycle completion fan-in.

The implementation must also preserve the current single-count direction
semantics. The capacity/status shell does not arbitrate multiple
same-direction request events asserted in the same cycle. A future
admitted-pulse prerequisite therefore needs a bounded mutual-exclusion
assertion for selected request events, or it would generate two transaction
identity pulses while the direction counter increments only once.

## Readiness Conclusion

Do not implement per-ID queue state or queue-head response demux next. That
would still combine admitted enqueue, queue storage, dequeue, response demux,
assertions, duplicate concrete-ID validation changes, and residue movement in
one behavior slice.

Do implement the admitted per-transaction request pulse prerequisite next.
That slice is narrow enough for review and is the missing boundary shared by
all later issue-order queue behavior.

The admitted-pulse slice must still keep duplicated concrete same-ID
transactions fail-closed. It does not accept same-ID reuse, does not generate
queue state, and does not change queue-head response demux.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`:

```text
Implement AXI same-ID issue-order queue admitted request pulses.
```

The implementation should:

- apply only to families that select `concrete-id-reuse issue-order-queue`;
- generate one scalar admitted-request pulse per concrete transaction in the
  selected family, using internal scalar storage pulse targets unless the
  implementation proves an output is required;
- derive each admission guard from transaction request event, current
  direction pending storage, family max-pending, and same-cycle completion
  fan-in, not from the generated `can_accept` output value;
- add a runtime assertion that at most one selected same-direction request
  event is active in the same cycle when admitted request pulses are generated;
- report the generated admitted-request boundary under `same_id_ordering`
  without setting `accepted_same_id_reuse: true` or
  `generated_queue_behavior: true`;
- keep duplicated concrete same-ID transactions fail-closed with the `.96`
  selected-not-generated diagnostic;
- keep per-ID queue storage, queue-head response demux, dequeue behavior,
  queue overflow/underflow assertions, accepted same-ID reuse, direct backend
  lowering, and VHDL deferred.

## Expected Report Shape

The next slice should keep the existing report schema and add bounded metadata
under the selected family. A suitable shape is:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: admitted_request_boundary
      implementation_status: admitted_request_pulses_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      admitted_request_boundary:
        guard_source: capacity_storage_and_completion_fanin
        selected_request_events:
          - axi0_r0_request
        generated_pulses:
          - transaction: r0
            pulse: axi0_r0_admitted_request_pulse_q
        generated_assertions:
          - axi0_read_issue_order_queue_request_onehot0
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

The exact generated names may differ, but the report must distinguish
admitted request pulses from generated queue behavior.

## Diagnostics And Non-Goals

The next slice should fail closed or keep existing fail-closed behavior for:

- duplicated concrete same-ID reuse under `issue-order-queue`;
- selected family with absent or zero-width ID metadata;
- selected family with no concrete transactions;
- malformed or duplicate transaction request events;
- selected same-direction request events that cannot be proven mutually
  exclusive by source shape and lack a runtime assertion owner;
- any attempt to claim generated queue-head response demux before queue state
  exists.

It must not implement:

- accepted concrete same-ID reuse;
- per-ID queue storage;
- enqueue/dequeue queue state transitions;
- queue-head response-demux for write, read single-beat, or read burst-last;
- read-data interleaving/reassembly changes;
- scoreboard policy;
- queued/blocking policy;
- full AXI manager syntax;
- profile aliases;
- direct backend lowering or VHDL behavior.

## Validation For This Audit

Audit gates:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This audit changes no behavior. If `.98` cannot generate admitted request
pulses without accepting duplicated concrete same-ID reuse or without changing
queue-head response demux, `.98` must be narrowed to a report-only or
assertion-only prerequisite before queue state work proceeds.
