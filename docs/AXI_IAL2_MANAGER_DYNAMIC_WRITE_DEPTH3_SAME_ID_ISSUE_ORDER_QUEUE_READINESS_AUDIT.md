# AXI IAL2 Manager Dynamic Write Depth-3 Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.481`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.481` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.482`, direct bounded implementation of
one generated all-dynamic write BID same-ID `issue-order-queue` with exactly
three dynamic write transactions and depth 3.

No parser, generator, PPIF sample, support-accounting catalog, generated
HDL/FSM artifact, report JSON, test, HDL/runtime behavior, read queue,
read-data, mixed dynamic/static queue, scoreboard, direct backend behavior,
backend-language variant, or VHDL behavior changes in this audit.

## Audited Candidate

The selected candidate shape is intentionally narrow:

```text
write transactions: w0, w1, w2
all transaction IDs: dynamic
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
write-max-pending: at least 3
queue depth: 3
queue groups: one generated dynamic write group
```

This is the smallest broader dynamic queue cardinality step after the shipped
two-transaction write, read single-beat, and read burst-last dynamic queue
families because it widens queue depth and covered transaction cardinality
without adding read-side `RLAST`, read-data consumers, raw `ARLEN`,
beat-count validation, output banks, mixed static-ID exclusion, or scoreboard
semantics.

## Findings

The current dynamic same-ID issue-order queue admission gate is still the
local behavior blocker. It requires exactly one generated queue group with
`depth == 2` and exactly two transactions, allocates storage with a fixed
slot loop over `0 .. 1`, assigns transaction slot signals over `0 .. 1`, and
records the generated queue group with `depth => 2`.

The surrounding dynamic queue machinery is already depth/list driven. The
transition generator iterates `_same_id_issue_order_queue_state_sequences`
using `group->{depth}`, considers any selected matching slot for dequeue,
and uses the transaction list for enqueue and onehot terms. Dynamic
assignment generation iterates `0 .. depth - 1`, moves retained IDs by slot,
and captures the current request ID source for the enqueue transaction.
State expressions, full checks, raw/selected match expressions, remaining
after dequeue checks, queue reports, and generated assertions also derive
slot coverage from `group->{depth}` and transaction lists.

A direct helper probe against a synthetic depth-3 dynamic write group produced
99 transition rules, 19 generated assertions, and 33 same-transaction refresh
rules. The probe included depth-3 tail-selected refresh forms such as:

```text
axi0_write_dynamic_same_id_issue_order_w1_w0_w2_dequeue_enqueue_w2
axi0_write_dynamic_same_id_issue_order_w2_w0_w1_dequeue_enqueue_w1
axi0_write_dynamic_same_id_issue_order_w2_w1_w0_dequeue_enqueue_w0
```

The report/static surface has explicit two-transaction expectations today.
The generated policy currently reports
`first_generated_scope: write_bid_two_dynamic_transactions`; focused
generator, parser/CLI, and dynamic-ID tests assert `w0`/`w1` transaction
lists, two slots, two generated response-demux rules, and depth-2 slot
storage. The public PPIF sample and support-accounting catalog also document
the shipped two-transaction sample only.

## Selected Next Leaf

`.482` should directly implement only the bounded write shape audited above.
The implementation may widen the existing dynamic write queue builder from
the hard-coded depth-2/two-transaction gate to accept exactly depth 3 with
three all-dynamic write transactions when the response demux is generated BID
completion and `write-max-pending` admits the three pending writes.

`.482` should keep the shipped depth-2 dynamic write/read/read-burst-last
queues unchanged, and should leave read-side depth-3 queues, read-data,
mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL to later exact owners.

## Implementation Boundaries

The behavior slice should update:

- dynamic queue admission, storage allocation, transaction slot signals, and
  queue-group depth for exactly the depth-3 all-dynamic write BID candidate;
- public report vocabulary for the new write scope, including covered
  transactions, generated response-demux rules, generated completion signals,
  generated queue depth, slot storage, generated update rules, generated
  assertions, and identity recapture fields;
- focused `t/1436`, `t/1437`, and `t/1438` expectations for the new sample;
- one checked-in PPIF sample and support-accounting entry for the depth-3
  write queue;
- README, roadmap, mdBook, task-tree, Memory, and Knowledge Map records.

The slice should not generalize arbitrary dynamic queue depths, multiple
dynamic queue groups, mixed dynamic/static issue-order queues, read depth-3
queues, or scoreboard behavior.

## Validation Plan

The implementation slice should run focused syntax checks and direct helper
probes first, then run RAM-guarded generated-sample schedule/check/semantic
or focused test probes where feasible. It should also run the standard
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
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.480` selector, `.479`
queue report fields, and `.477` generated queue ID-refresh behavior remain
unchanged.
