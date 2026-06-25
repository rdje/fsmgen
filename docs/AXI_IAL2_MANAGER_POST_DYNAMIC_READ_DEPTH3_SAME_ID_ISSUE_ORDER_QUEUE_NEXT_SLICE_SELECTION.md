# AXI IAL2 Manager Post Dynamic Read Depth-3 Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.486`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.486` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.487`, readiness audit for generated
all-dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue`
cardinality widening from the shipped two-transaction dynamic read burst-last
queue to one bounded depth-3, three-transaction queue.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, read-data, mixed
dynamic/static queue, scoreboard, direct backend behavior, backend-language
variant, external converter dependency, or VHDL behavior changes in this
selector.

## Why Read Burst-Last Depth-3 Next

`.485` proved the read-side depth-3 compact runtime-ID issue-order queue for
generated single-beat `RID` completion. The selected next audit keeps the same
three all-dynamic read transactions and captured-`ARID` queue representation,
but adds only the already-shipped burst-last `RLAST` completion semantics.

This is the smallest post-`.485` widening because `.463` already shipped the
two-transaction dynamic read burst-last queue and documented the required
RLAST-specific behavior:

- raw `RID` matching selects the earliest captured runtime-ID slot;
- non-final matching beats do not dequeue;
- final selected matches add the one-bit `last_signal`;
- generated completions use
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- completion semantics are
  `earliest_matching_captured_runtime_id_and_last_signal`.

Read-data over depth-3 queues remains downstream of generated response-demux
behavior. Mixed dynamic/static queues need reserved static-ID policy and mixed
request conflict rules. Dynamic scoreboards remain a distinct policy surface.
Arbitrary cardinality is broader than the bounded depth-3 pattern.

Backend-language variants and SystemVerilog-to-Verilog portability remain
owned by `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`. FSMGen-owned
generation/lowering stays the default; external converters such as `sv2v` are
not selected dependencies in this IAL2 queue slice.

## Selected Next Leaf

`.487` should audit this exact candidate shape:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated burst-last RID/RLAST completion
response-demux.read.response-scope: burst-last
response-demux.read.last-signal: one bit
read-max-pending: at least 3
queue depth: 3
queue groups: one generated dynamic read burst-last group
```

The audit should decide whether direct implementation can safely widen the
existing dynamic read burst-last queue from depth 2 to depth 3, or whether a
smaller prerequisite is needed first.

## Known Local Gates To Audit

The current dynamic read queue planner admits exactly two all-dynamic read
transactions, or exactly three only when `response_scope` is `single-beat`.
The dynamic queue builder admits read depth 3 only for single-beat entries
without `last_signal`. Same-ID ordering scope reporting currently maps any
read entry with `last_signal` to `read_rid_rlast_two_dynamic_transactions`.

`.487` should audit those local gates plus the focused t/1436, t/1437, and
t/1438 report/helper surfaces before any behavior change.

## Deferred Alternatives

Read-data over depth-3 dynamic queues remains deferred until generated
burst-last depth-3 response-demux behavior exists or is explicitly rejected by
the readiness audit.

Mixed dynamic/static dynamic issue-order queues remain deferred because they
combine runtime-ID queue ordering with reserved static IDs and mixed request
conflict rules.

Dynamic scoreboards remain deferred. `scoreboard` has different storage and
completion semantics from issue-order queues.

Arbitrary dynamic queue cardinality, direct backend behavior,
backend-language variants, external converter dependency selection, and VHDL
remain outside this IAL2 SystemVerilog-backed selector.

## Validation

This selector closed with documentation and continuity gates only. `.487`
owns any generated behavior probe, temporary candidate diagnostics, code,
test, sample, support-accounting, or report-surface update.

## Rollback

Rollback removes this selection note, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.485` generated
depth-3 read single-beat behavior, `.482` generated depth-3 write behavior,
and `.463` generated depth-2 read burst-last behavior remain unchanged.
