# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Identity Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.477`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.477` ships state-key-preserving dynamic
same-ID `issue-order-queue` recapture ID refresh for the existing bounded
two-transaction generated dynamic queue families.

The dynamic transition generator now retains a transition whose transaction
identity state key is unchanged when, and only when, the selected dequeued
transaction is the same transaction admitted again in that cycle. That keeps
ordinary no-op dynamic queue transitions suppressed while emitting the missing
ID-refresh rules for same-transaction recapture.

Static concrete-ID issue-order queue transition generation is unchanged.

## Generated Rule Shape

The generated dynamic queue update rule list now includes one-entry and
tail-selected identity-preserving refresh rules such as:

```text
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0
axi0_write_dynamic_same_id_issue_order_w1_w0_dequeue_enqueue_w0
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r0
```

The existing assignment helper already handled the correct ID update once the
transition was emitted:

- one-entry write recapture refreshes slot 0 from `axi0_awid`;
- tail-selected write recapture refreshes slot 1 from `axi0_awid`;
- one-entry read recapture refreshes slot 0 from `axi0_arid`; and
- tail-selected read recapture refreshes slot 1 from `axi0_arid`.

Retained non-dequeued slots preserve their existing captured runtime IDs.

## Report Surface

`same_id_ordering.dynamic_id_reuse_policy.*.generated_queues[].
generated_update_rules` remains a literal list of emitted queue update rules.
The list now includes the state-key-preserving same-transaction ID-refresh
rules for generated dynamic write BID, read single-beat RID, read burst-last
RID/RLAST, and read-data-consuming queue samples that reuse those queue
families.

No classic response-demux recapture vocabulary is added to queue reports in
this slice. The fields `same_cycle_release_recapture_policy`,
`release_recapture_rule`, `release_recapture_source`, and
`release_recapture_transaction` remain exclusive to dynamic response-demux
capture state.

A positive explicit queue recapture support field remains future exact-owner
work. `.478` owns the next public report/static contract selection now that
the behavior exists.

## Scope Preserved

`.477` does not change parser syntax, PPIF source samples, support-accounting
catalog entries, generated sample files, direct backend behavior,
backend-language variants, scoreboards, broader queue cardinality,
mixed dynamic/static queues, or VHDL behavior.

## Validation

Passed:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Lightweight direct helper probes confirmed:

```text
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0 -> slot0_id=axi0_arid
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r0 -> slot1_id=axi0_arid
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0 -> slot0_id=axi0_awid
axi0_write_dynamic_same_id_issue_order_w1_w0_dequeue_enqueue_w0 -> slot1_id=axi0_awid
```

RAM-guarded full-generation and focused `prove` attempts were stopped before
data because host memory was already above the default 88% cutoff. No
unguarded retry and no cutoff raise were used.

## Rollback

Rollback restores the dynamic transition generator's same-state skip,
removes the new report/helper expectations, and removes this behavior record,
the Knowledge Map fact card, and the README/ROADMAP/mdBook/task-tree/MEMORY
updates.
