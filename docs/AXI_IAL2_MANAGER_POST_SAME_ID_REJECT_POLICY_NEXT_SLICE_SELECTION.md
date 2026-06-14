# AXI IAL2 Manager Post Same-ID Reject Policy Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.93`

Date: 2026-06-14

## Purpose

This selector chooses the next AXI manager feature-completeness owner after
`.92` shipped explicit same-ID reuse `reject` policy parser/report metadata
and static validation.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
  - `ppif/axi_manager_capacity_status_response_demux.ppif`
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Live State

The `.92` sample reports a policy-only same-ID section:

```text
same_id_ordering.mode: concrete_id_reuse_policy
same_id_ordering.generated_behavior: false
same_id_ordering.concrete_id_reuse_policy.read.policy: reject
same_id_ordering.concrete_id_reuse_policy.read.generated_queue_behavior: false
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

Concrete-ID samples still use assertion-only request/response ID checks and
keep same-ID ordering under ID/response residue:

```text
id_response_rule_engine.mode: concrete_id_assertions
id_response_rule_engine.residue:
  - auto_id_allocation
  - id_release
  - same_id_ordering
  - response_demux
```

Generated auto-ID samples remain a separate conservative case: they avoid
same-ID concurrency through allocator free-ID guards and assertions. That is
not accepted concrete-ID same-ID reuse.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.94`:

```text
Select AXI same-ID issue-order queue policy contract.
```

The next leaf should define the public source and report contract for accepted
same-ID reuse before parser/report metadata or generated queue behavior. It
should decide:

- whether the selected spelling is
  `(same-id-ordering (read|write (concrete-id-reuse issue-order-queue)))`
  or a narrower variant;
- whether the first boundary is read-only, write-only, or family-local for
  either response family;
- how queue depth is bounded, most likely by the existing manager
  `max-pending` and transaction set rather than a new hidden unbounded queue;
- what generated issue-order state, enqueue/dequeue events, and queue-head
  predicates later implementation slices are allowed to emit;
- how same-ID response demux must use queue-head transaction identity instead
  of only `RID == constant` or `BID == constant`;
- what diagnostics apply when ID families, transactions, response signals,
  completion events, or selected policy arms are missing or inconsistent;
- the exact `same_id_ordering` and `id_response_rule_engine` report vocabulary
  for accepted same-ID reuse and remaining residue;
- validation gates and rollback boundaries for later parser/report and
  generated behavior slices.

## Why Not Implement Queues Directly

Direct generated queue behavior would introduce user-visible scheduling,
generated state, generated rules, response-demux ownership, and new
diagnostics while the public contract still rejects `issue-order-queue`.
That would make accepted same-ID reuse implicit rather than source-selected.

## Why Not Do Concrete-ID Response Demux First

Concrete-ID response demux cannot distinguish two in-flight same-ID
transactions by `RID` or `BID` alone. The demux rule needs selected
issue-order state and must complete the queue head for that response family.

## Why Not Select Scoreboard First

A scoreboard is a broader policy than the minimal AXI same-ID issue-order
queue. The current evidence only requires preserving same-ID response issue
order for the selected response family. Scoreboards remain deferred until a
later owner selects a broader matching policy.

## Why Not Switch To Verification Code Generation

Verification-code generation remains a valid future roadmap lane, but this
frontier is still closing synthesizable SystemVerilog-backed AXI manager
feature gaps. The verification/VIP route should get its own task-tree owner
when selected, without being mixed into the same-ID queue contract slice.

## Validation For This Selector

Selector gates:

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

This selector changes no behavior. If `.94` cannot define a small
issue-order queue policy contract, it must select a smaller prerequisite or
defer queue behavior before parser, generator, sample, support-accounting, or
HDL behavior changes.
