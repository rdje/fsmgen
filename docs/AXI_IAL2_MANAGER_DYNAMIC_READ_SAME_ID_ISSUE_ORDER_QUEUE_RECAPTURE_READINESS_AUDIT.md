# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Recapture Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.474`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.474` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.475`, public report/static contract
selection for generated dynamic same-ID `issue-order-queue` same-cycle
selected-dequeue-plus-enqueue recapture.

This audit does not select a new queue state-machine implementation. The
selected generated dynamic same-ID queue already supports same-cycle queue
recapture for the bounded two-transaction shapes: a selected final dequeue can
occur in the same cycle as one admitted request, and the newly enqueued
transaction captures the current request ID source into the queue slot. The
remaining gap is public/report vocabulary and static support wording. Queue
reports expose the generated `*_dequeue_enqueue_*` update rules, while classic
dynamic response-demux reports expose explicit `same_cycle_release_recapture`
fields. The next safe slice is therefore a narrow contract-selection leaf that
pins the report/static alignment before any report-key or generator-source
change.

This readiness audit changes no parser, generator, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Evidence Read

The audit read:

- `.473` multi-beat output-bank behavior over generated dynamic read same-ID
  `issue-order-queue` runtime-validation read-data.
- `.472`, `.471`, `.469`, and `.467` queue read-data readiness/behavior
  records.
- Generated dynamic read same-ID queue behavior for single-beat `RID` and
  burst-last `RID && RLAST` response-demux.
- Generated dynamic write same-ID queue behavior and compact runtime-ID queue
  representation selection.
- Single-active, multiple all-dynamic, and mixed dynamic/static
  release-and-recapture records and report fields.
- Current response-demux release/recapture helpers, dynamic issue-order queue
  transition specs, queue assignment rules, queue report projection, parser/CLI
  expectations, support-accounting/check/semantic surfaces, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

A RAM-guarded schedule report probe for the `.473` public sample confirmed
that the report already publishes generated same-cycle dequeue-plus-enqueue
rules:

```text
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r1
axi0_read_dynamic_same_id_issue_order_r1_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r1
```

The same probe found no classic `same_cycle_release_recapture_policy` or
`release_recapture_*` fields in the queue report, which is expected for the
current queue-specific report shape.

## Current Boundary

The dynamic issue-order queue transition builder enumerates:

- no-dequeue plus one enqueue;
- selected final dequeue only;
- selected final dequeue plus one enqueue in the same cycle; and
- compaction of retained transactions.

For dynamic queues, the selected match is the earliest matching captured
runtime ID slot. Burst-last read queues require the response event, raw `RID`
slot match, and `RLAST` before dequeue. Non-final matching read beats are raw
read-data beats only: they do not dequeue the queue.

The dynamic queue assignment path preserves retained slot IDs, clears emptied
slots, and captures the current request ID source for the newly enqueued
transaction. This is the queue-owned form of same-cycle recapture. It is not
the classic dynamic response-demux form that rewrites a single busy/selected-ID
register through a `*_dynamic_id_release_recapture` rule.

Read-data consumers are already behind the queue-selected matched-beat
boundary:

- scalar `.467` capture uses generated queue completion pulses;
- `.469` raw `ARLEN` capture happens at request time;
- `.471` runtime validation increments beat counters from the queue-selected
  matched read beat; and
- `.473` multi-beat output banks capture per-lane data/status from the same
  matched-beat source.

Because queue recapture updates the queue after the selected final completion
and captures a new request ID for a new logical transaction, it does not require
new read-data lane, beat-count, or aggregate-status machinery for the selected
two-transaction queue shape.

## Selected `.475` Contract-Selection Boundary

`.475` should select the exact public report/static contract for queue-owned
same-cycle recapture before implementation. It should pin:

- whether the explicit report field lives under `same_id_ordering` queue
  groups, `response_demux.read`, or both;
- the field names and values for same-cycle selected-dequeue-plus-enqueue
  support;
- how the existing `generated_update_rules` `*_dequeue_enqueue_*` list relates
  to the new explicit support field;
- whether read single-beat, read burst-last, write, and read-data-consuming
  queue samples all share the same vocabulary or whether `.475` selects only
  the read burst-last/read-data boundary first;
- parser/CLI test expectations for the selected samples;
- support-detail and unsupported-residue wording that distinguishes
  queue-owned recapture from classic `release_recapture_rule` state;
- documentation and Knowledge Map wording; and
- rollback and validation gates for a later implementation leaf.

The selected contract-selection leaf should not change parser behavior, queue
transition generation, PPIF samples, support accounting, generated artifacts,
tests, JSON fields, HDL, runtime behavior, direct backend behavior,
backend-language variants, or VHDL until the report/static contract is pinned.

## Diagnostics

No new diagnostic is required by `.474`. `.475` should decide whether any
later implementation needs a diagnostic change. The expected answer is likely
no parser diagnostic: the selected queue shapes already admit or reject source
contracts correctly. The gap is report/static publication, not source
admission.

## Non-Goals

`.474` changes no behavior. `.475` should also keep these future owners out of
scope unless it explicitly selects another smaller prerequisite:

- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Plan

For `.474`, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The RAM-guarded schedule probe used during the audit was:

```bash
scripts/run_with_ram_guard.sh -- bash -lc 'env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif | rg "dynamic_transaction_id_behavior|same_cycle_release_recapture|release_recapture|dequeue_enqueue|generated_update_rules|dynamic_same_id_issue_order_queue"'
```

## Rollback

Rollback removes this audit document, its Knowledge Map card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. No generated behavior or public
source syntax changed in `.474`.
