# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Identity Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.476`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.476` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.477`, direct implementation of
state-key-preserving dynamic same-ID `issue-order-queue` recapture ID refresh.

The current generated dynamic queue transition builder skips transitions whose
transaction-identity state key is unchanged. That is correct for ordinary
no-op queue state, but it is not sufficient for dynamic runtime-ID queues:
dequeueing the selected transaction and admitting the same transaction again in
the same cycle can leave the one-hot transaction identity unchanged while the
slot-local captured request ID must refresh to the new `AWID` or `ARID`.

`.476` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
HDL, runtime behavior, direct backend behavior, backend-language variant,
scoreboard, or VHDL behavior.

## Evidence Read

The audit read:

- `.475` report/static contract selection and `.474` readiness audit.
- Generated dynamic write, read single-beat, read burst-last, scalar read-data,
  raw-`ARLEN`, runtime-validation, and multi-beat queue records.
- Dynamic queue transition, assignment, assertion, and report code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`.
- Parser/generator focused tests for generated dynamic write/read/read-data
  issue-order queue samples.
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

A RAM-guarded report probe across the public write/read/read-data queue
samples was attempted, but the guard stopped before producing queue-rule data
because host memory was already at the default 88% cutoff:

```text
ram-guard: host memory 88.4% reached cutoff 88%
```

No unguarded retry and no higher memory cutoff were used. The audit decision
therefore rests on code inspection and existing focused test/report
expectations, plus the `.475` guarded read-sample probe.

## Current Behavior Boundary

`_dynamic_same_id_issue_order_queue_transition_specs` builds dynamic queue
transitions from transaction identity state:

- it enumerates selected dequeue options plus zero/one enqueue options;
- after dequeue, it permits enqueue of a transaction that is no longer
  remaining;
- it skips any transition where
  `_same_id_issue_order_queue_state_key($from)` equals the destination state
  key.

For a one-entry queue, a selected completion for `r0` plus a same-cycle new
`r0` request produces identity state `[r0] -> [r0]`. The state-key skip omits
the needed `r0_dequeue_enqueue_r0` rule. The same shape exists for `w0`, `w1`,
`r1`, and for two-entry tail-selected states such as `[r1, r0] -> [r1, r0]`.

The assignment helper already has the needed ID-refresh behavior if the
transition is emitted. `_dynamic_same_id_issue_order_queue_assignments`
excludes the selected dequeued transaction from retained slots; when the
destination slot holds the enqueued transaction, it assigns that slot ID from
`request_id_source`.

The dynamic queue assertions also make the source shape legal rather than
fail-closed. The per-transaction `*_no_duplicate_after_dequeue` assertion
allows an enqueue when that transaction is not remaining after the selected
dequeue, and `enqueue_requires_space_or_dequeue` allows enqueue when a selected
dequeue frees capacity.

## Selected `.477` Implementation Boundary

`.477` should add state-key-preserving dynamic queue transitions for the cases
where:

- a selected dequeue is present;
- an enqueue of the same transaction is present in the same cycle; and
- the destination transaction identity sequence is unchanged only because the
  slot-local captured runtime ID must be refreshed.

The implementation should emit literal generated update rules such as:

```text
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r0
```

The exact set should be derived from the existing transition enumeration for
write, read single-beat, read burst-last, and queue read-data-consuming samples.
For each emitted state-key-preserving rule, the slot ID assignment must refresh
from the current request ID source while preserving any retained slot IDs.

`.477` should update focused tests and report expectations so
`generated_update_rules` remains a literal list of emitted queue rules. It
should not add classic `same_cycle_release_recapture_policy` or
`release_recapture_*` fields to queue reports. A positive explicit queue
recapture support field remains a later exact owner after the behavior is
present.

## Diagnostics

No parser diagnostic is selected. The existing public source shape is accepted
and its assertions already allow same-transaction reissue when the selected
dequeue frees the transaction. The correct next step is to generate the missing
ID-refresh rules, not to reject the source shape.

## Non-Goals

`.477` should not widen beyond the current bounded generated dynamic queue
families unless it selects a smaller prerequisite first:

- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.476`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.477` should use RAM-guarded focused generator probes/tests for the affected
queue samples and avoid broad unguarded `fsmgen` or `prove` runs.

## Rollback

Rollback removes this audit document, its Knowledge Map card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. No generated behavior or public
source syntax changed in `.476`.
