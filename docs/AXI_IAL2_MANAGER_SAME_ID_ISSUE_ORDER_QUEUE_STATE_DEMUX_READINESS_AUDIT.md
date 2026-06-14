# AXI IAL2 Manager Same-ID Issue-Order Queue State And Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`

Date: 2026-06-14

## Purpose

This audit decides the next safe owner after `.98` shipped admitted request
pulses and `.99` selected a queue-state plus queue-head demux readiness pass.
The goal is to prevent accepted concrete same-ID reuse from becoming legal
before the generated queue identity state and response routing contract are
precise enough to implement and review.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, samples, support accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- current schedule JSON for
  `ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`
- current schedule JSON for generated write `BID` response demux
  `ppif/axi_manager_capacity_status_response_demux.ppif`
- current schedule JSON for generated read `RID` plus `RLAST` response demux
  `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`
- current same-ID, ID/response, response-demux, storage, rule, and assertion
  substrate in `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- focused generator and PPIF/CLI tests covering admitted request pulses,
  duplicate same-ID diagnostics, and generated response demux
- public PPIF samples, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map fact cards

## Live State

The public `issue-order-queue` sample now has a generated admitted request
boundary, but not generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: admitted_request_boundary
      implementation_status: admitted_request_pulses_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      admitted_request_boundary:
        guard_source: capacity_storage_and_completion_fanin
        generated_pulses:
          - transaction: r0
            concrete_id: 3
            request_event: axi0_r0_request
            pulse: axi0_r0_admitted_request_pulse_q
            rule: axi0_r0_admitted_request
```

The same report still carries honest residue:

```yaml
same_id_ordering:
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues

id_response_rule_engine:
  residue:
    - auto_id_allocation
    - id_release
    - same_id_ordering
    - response_demux
```

Duplicated concrete same-ID transactions still fail closed under selected
`issue-order-queue`. That remains correct because the admitted pulse only
names the enqueue boundary. It does not remember transaction issue order, does
not identify a queue head, and does not route a concrete same-ID response.

## Response Demux Boundary

Current generated response demux is auto-ID-state based. The write `BID` path
and read `RID`/`RLAST` path both match a raw response event against generated
auto-ID transaction state:

```text
raw_response_event && transaction_busy && response_id == selected_id
```

That is correct for the existing auto-ID lifecycle samples. It is not enough
for concrete same-ID issue-order queues. In the queue case, the response ID
selects the concrete ID queue, and the queue head selects the authored
transaction. ID-only matching cannot distinguish `r0` from `r1` when both use
the same concrete `RID` value.

Queue-head demux therefore cannot be the next behavior slice unless the queue
state representation already exists.

## Substrate That Is Ready

The existing lower layers are sufficient for selecting a bounded
representation:

- admitted request pulses already provide one enqueue input per selected
  concrete transaction;
- per-direction pending storage and max-pending bounds already exist;
- positive-width concrete ID metadata already provides a family and concrete
  value for grouping;
- scalar storage, guarded rules, pulse actions, and runtime assertions already
  lower through the IAL1 and IAL0 path;
- response-demux reports already have space for generated rules,
  generated completion signals, assertions, and residue;
- same-ID reports already distinguish policy selection, admitted boundary,
  accepted same-ID reuse, generated queue behavior, and residue.

## Missing Contract

The implementation is blocked by representation choices, not by a lower-layer
code primitive. Before queue behavior changes, the project needs one narrow
owner to select:

- grouping key: family plus concrete ID value;
- static bound: `min(family max-pending, selected concrete transaction count)`
  for each generated queue;
- transaction identity encoding in storage and reports;
- queue storage shape, including empty/full/head metadata and reset values;
- enqueue rule names and guards, sourced only from admitted request pulses;
- dequeue event definition for write response, read single-beat response, and
  read burst-last response scopes;
- queue-head response-demux report vocabulary;
- overflow, underflow, unknown-head, and request mutual-exclusion assertions;
- duplicate concrete same-ID diagnostic movement from fail-closed to accepted
  only when the generated queue and queue-head demux behavior are present;
- residue movement for `same_id_ordering` and `id_response_rule_engine`.

Choosing those in the same slice as behavior implementation would combine too
many public and generated contracts.

## Why Not Implement Queue State Directly

Direct queue-state implementation would need to change duplicate-ID
validation, emit new storage, generate enqueue/dequeue rules, decide reset and
overflow behavior, update reports, and preserve response semantics for write,
read single-beat, and read burst-last forms. It would still leave queue-head
demux behavior either underspecified or coupled into the same large slice.

That is too broad for signoff-level review.

## Why Not Implement Queue-Head Demux First

Queue-head demux needs a queue nonempty predicate and a concrete transaction
identity at the queue head. Without that state, the demux rule can only see a
raw `BID` or `RID` value. For same-ID reuse, that value intentionally matches
more than one authored transaction.

Queue-head demux must follow, or be implemented with, the selected queue state
representation. It should not be first.

## Why Not Do Static Report Alignment First

The current report is already honest:

- `accepted_same_id_reuse` is `false`;
- `generated_queue_behavior` is `false`;
- selected `issue-order-queue` families report only admitted request pulses;
- duplicated concrete same-ID transactions still fail closed;
- same-ID queue and response-demux residue remain visible.

Another report-only slice would not unlock behavior. The missing piece is the
bounded representation contract that later behavior can implement.

## Readiness Conclusion

Select a smaller helper prerequisite next: a representation-selection slice for
bounded AXI same-ID issue-order queue state.

That next owner should not ship generated behavior. It should write down the
precise queue storage/report/diagnostic shape and split the following
behavior-bearing implementation into reviewable pieces.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.101`:

```text
Select bounded AXI same-ID issue-order queue state representation.
```

The `.101` slice should:

- define the generated queue representation for family-local concrete-ID
  groups selected by `concrete-id-reuse issue-order-queue`;
- specify generated storage names, widths, reset values, head/empty/full
  metadata, and transaction identity encoding;
- specify enqueue/dequeue event names and the first behavior split after
  representation selection;
- specify report vocabulary for queue state and queue-head demux readiness
  without claiming generated queue behavior;
- define diagnostics and assertions that must exist before duplicated concrete
  same-ID reuse can be accepted;
- keep accepted same-ID reuse, queue state behavior, queue-head demux, direct
  backend lowering, and VHDL deferred.

## Validation For This Audit

Audit gates:

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

This audit changes only durable docs/task-tree state. Rolling it back restores
`.100` as the active readiness audit and does not affect generated artifacts
or public CLI behavior.
