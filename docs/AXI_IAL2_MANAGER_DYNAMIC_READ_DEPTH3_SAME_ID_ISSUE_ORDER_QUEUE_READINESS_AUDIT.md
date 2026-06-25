# AXI IAL2 Manager Dynamic Read Depth-3 Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.484`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.484` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.485`, direct bounded implementation of
one generated all-dynamic read single-beat `RID` same-ID `issue-order-queue`
with exactly three dynamic read transactions and depth 3.

No parser, generator, PPIF sample, support-accounting catalog, generated
HDL/FSM artifact, report JSON, test, HDL/runtime behavior, read burst-last,
read-data, mixed dynamic/static queue, scoreboard, direct backend behavior,
backend-language variant, external converter dependency, arbitrary
cardinality, or VHDL behavior changes in this audit.

## Audited Candidate

The selected candidate shape is intentionally narrow:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated single-beat RID completion
read-max-pending: at least 3
queue depth: 3
queue groups: one generated dynamic read single-beat group
```

This is the smallest read-side queue-cardinality step after `.482` because it
widens queue depth and covered dynamic read transaction count without adding
`RLAST`, read-data consumers, raw `ARLEN`, beat-count validation, output
banks, mixed static-ID exclusion, or scoreboard semantics.

## Findings

The current dynamic read single-beat issue-order queue behavior is generated
only for exactly two all-dynamic read transactions. The local read
response-demux planner still requires exactly two all-dynamic reads, requires
`read-max-pending` at least 2, and records the generated queue group with
`depth => 2`.

The shared dynamic queue builder is already depth/list driven for storage,
transaction slot signals, transition generation, assignments, state
expressions, selected-match expressions, report queue entries, and generated
assertions. The remaining explicit builder gate supports depth 2 for all
dynamic queue families and depth 3 only for write.

The same-ID ordering report currently has read scopes only for
`read_rid_two_dynamic_transactions` and
`read_rid_rlast_two_dynamic_transactions`. A read single-beat depth-3
implementation needs a distinct `read_rid_three_dynamic_transactions` scope
so focused reports can distinguish the widened public shape from the existing
two-read sample.

A lightweight private helper probe against a synthetic depth-3 dynamic read
single-beat group produced 99 transition rules, 19 generated assertions, and
zero duplicate rule names. The generated names include the same depth-3
cross-transaction disambiguation shape introduced for write, for example:

```text
axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_r0_enqueue_r2
axi0_read_dynamic_same_id_issue_order_r2_r1_r0_dequeue_enqueue_r0
```

The assertion list includes the third transaction completion-selected-match
assertion:

```text
axi0_read_dynamic_same_id_issue_order_r2_completion_selected_match
```

The focused generator, PPIF/CLI, and dynamic-ID tests already have
two-transaction dynamic read queue report helpers. The implementation slice
needs a new support-accounted public PPIF sample, support-accounting catalog
entry, and focused expectations for `r2`, slot2 storage, depth-3 report
metadata, generated response-demux rules, update-rule disambiguation, and
queue assertions.

## Selected Next Leaf

`.485` should directly implement only the bounded read single-beat shape
audited above. The implementation may widen the existing dynamic read queue
planner from the hard-coded depth-2/two-transaction gate to accept exactly
depth 3 with three all-dynamic read transactions when the response demux is
generated single-beat `RID` completion and `read-max-pending` admits the
three pending reads.

`.485` should keep the shipped depth-2 dynamic write/read/read-burst-last
queues and the `.482` write depth-3 queue unchanged. It should leave read
burst-last depth-3 queues, read-data over depth-3 dynamic queues, mixed
dynamic/static queues, scoreboards, arbitrary dynamic queue cardinality,
direct backend behavior, backend-language variants, external converter
dependency selection, and VHDL to later exact owners.

## Implementation Boundaries

The behavior slice should update:

- dynamic read single-beat queue admission, storage allocation,
  transaction-slot signals, and queue-group depth for exactly the depth-3
  all-dynamic read `RID` candidate;
- public report vocabulary for the new read single-beat scope, including
  covered transactions, generated response-demux rules, generated completion
  signals, generated queue depth, slot storage, generated update rules,
  generated assertions, and identity recapture fields;
- focused `t/1436`, `t/1437`, and `t/1438` expectations for the new sample;
- one checked-in PPIF sample and support-accounting entry for the depth-3
  read single-beat queue;
- README, roadmap, mdBook, task-tree, Memory, and Knowledge Map records.

The slice should not generalize arbitrary dynamic queue depths, generated
read burst-last depth-3 queues, read-data over depth-3 dynamic queues,
multiple dynamic queue groups, mixed dynamic/static issue-order queues,
scoreboard behavior, backend-language variants, external converter
dependencies, or VHDL.

## Validation Plan

The implementation slice should run focused syntax checks and direct helper
probes first, then RAM-guarded generated-sample schedule/check/semantic or
focused test probes where feasible. It should also run the standard
documentation and doctrine gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Any RAM-guard cutoff should be recorded as a caveat. No unguarded retry or
cutoff raise is selected by this audit.

## Rollback

Rollback removes this audit note, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.483` selector, `.482`
generated depth-3 write behavior, and existing two-transaction dynamic read
queue behavior remain unchanged.
