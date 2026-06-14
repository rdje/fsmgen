# AXI IAL2 Manager Post-Admitted Request Pulses Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.99`

Date: 2026-06-14

## Purpose

This selector chooses the next AXI manager feature-completeness owner after
`.98` shipped admitted request pulses for selected same-ID
`issue-order-queue` families.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, samples, support accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- live schedule JSON for
  `ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`
- focused `.98` generator and PPIF/CLI validation evidence in the task tree
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Live State

The public same-ID issue-order queue sample now reports a generated admitted
request boundary:

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
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

The generated `.isf` and `.fsm` contain the internal admitted request pulse,
but the pulse is not queue state and is not a public output. The selected
family still does not accept duplicated concrete same-ID reuse.

The ID/response rule engine still reports:

```text
auto_id_allocation
id_release
same_id_ordering
response_demux
```

That residue is still honest for the concrete-ID issue-order queue sample:
auto-ID allocation/release and generated response demux are separate
behavior families, and accepted concrete same-ID reuse still needs explicit
queue-head behavior.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`:

```text
Audit AXI same-ID issue-order queue state and queue-head demux readiness.
```

The next leaf should decide whether the next behavior-bearing owner can be a
bounded queue-state/enqueue/dequeue implementation, a queue-head response-demux
refactor, a static-validation/report alignment prerequisite, or a smaller
helper substrate. It must do that before code changes.

## Why Not Implement Queue State Directly

Admitted request pulses solve only the enqueue boundary. Accepted same-ID
reuse still requires all of the following to line up:

- per-ID, family-local, bounded queue storage;
- enqueue from admitted request pulses only;
- dequeue on queue-head transaction completion;
- response demux that uses the queue head, not ID-only matching;
- diagnostics that stop duplicated concrete same-ID reuse from becoming legal
  before queue-head behavior exists;
- queue overflow/underflow and request/response consistency assertions;
- report movement for `accepted_same_id_reuse`, `generated_queue_behavior`,
  `same_id_ordering.residue`, and `id_response_rule_engine.residue`.

Bundling those directly into one implementation slice would be too broad and
would risk moving the public report contract before the queue-head semantics
are audited.

## Why Not Do Queue-Head Demux First

Queue-head demux needs queue state. For concrete same-ID reuse, `RID` or `BID`
selects the per-ID queue, but the queue head selects the authored transaction.
Without queue storage and nonempty/head metadata, response demux cannot
identify the concrete transaction it should complete.

The readiness audit should therefore evaluate queue storage and queue-head
demux together, then select the smallest safe behavior or prerequisite slice.

## Validation For This Selector

Selector gates:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This selector changes only durable docs/task-tree state. Rolling it back
restores `.99` as the active selector and does not affect generated artifacts
or public CLI behavior.
