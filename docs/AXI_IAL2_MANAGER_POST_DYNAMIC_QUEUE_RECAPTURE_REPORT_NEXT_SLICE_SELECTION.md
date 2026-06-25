# AXI IAL2 Manager Post Dynamic Queue Recapture Report Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.480`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.480` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.481`, readiness audit for generated
all-dynamic write BID same-ID `issue-order-queue` cardinality widening from
two transactions to one bounded depth-3, three-transaction queue.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, direct backend behavior,
backend-language variant, mixed dynamic/static queue, scoreboard, or VHDL
behavior changes in this selector.

## Why Depth-3 Dynamic Write First

The current generated dynamic queue behavior is deliberately limited to
selected two-transaction all-dynamic write BID, read single-beat RID, and read
burst-last RID/RLAST queue families. The implementation gate still requires
one generated queue group with `depth == 2` and exactly two all-dynamic
transactions.

The transition, assignment, state-expression, selected-match, and assertion
helpers are already written around `group->{depth}` and the transaction list.
That makes bounded all-dynamic cardinality the next smallest audit target, but
the admission gate, report vocabulary, focused tests, public PPIF sample, and
support-accounting surfaces still need a readiness audit before behavior
changes.

Write BID is the first cardinality audit because it exercises queue depth and
transaction cardinality without adding read burst-last gating, read-data
consumers, raw `ARLEN`, beat-count validation, or multi-beat output banks.

## Selected Next Leaf

`.481` should audit this exact candidate shape:

```text
write transactions: w0, w1, w2
all transaction IDs: dynamic
same-id-ordering.write: dynamic-id-reuse issue-order-queue
response-demux.write: generated BID completion
write-max-pending: at least 3
queue depth: 3
```

The audit should decide whether the direct implementation can safely widen the
existing dynamic queue builder to depth 3 for write BID only, or whether a
smaller prerequisite is needed first.

## Deferred Alternatives

Mixed dynamic/static dynamic issue-order queues remain deferred. They combine
runtime-ID queue ordering with reserved static IDs and mixed request conflict
rules; that is a broader semantic surface than all-dynamic cardinality.

Dynamic scoreboards remain deferred. `scoreboard` is a distinct policy with
different storage and completion semantics from issue-order queues.

Read single-beat and read burst-last depth-3 dynamic queues remain deferred
until after the write depth-3 readiness audit. Those shapes add read-side
completion semantics and, for burst-last/read-data consumers, additional
`RLAST`, raw-`ARLEN`, validation, and output-bank interactions.

Direct backend behavior, backend-language variants, and VHDL remain outside
this IAL2 SystemVerilog-backed selector.

## Validation Plan

The selector should close with docs/continuity gates only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.481` owns any code, test, sample, support-accounting, or generated behavior
probe.

## Rollback

Rollback removes this selection note, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.479` queue report
surface and `.477` generated queue behavior remain unchanged.
