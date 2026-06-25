# AXI IAL2 Manager Post Dynamic Write Depth-3 Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.483`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.483` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.484`, readiness audit for generated
all-dynamic read single-beat `RID` same-ID `issue-order-queue` cardinality
widening from two transactions to one bounded depth-3, three-transaction
queue.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, read-data, read
burst-last, mixed dynamic/static queue, scoreboard, direct backend behavior,
backend-language variant, external converter dependency, or VHDL behavior
changes in this selector.

## Why Read Single-Beat Depth-3 Next

`.482` proved the smallest all-dynamic queue-cardinality widening on the
write side. The generated write depth-3 shape now covers three compact
runtime-ID slots, three dynamic transactions, depth-driven report fields, and
depth-3 rule-name disambiguation for ambiguous selected-dequeue-plus-enqueue
rules.

Read single-beat depth-3 is the next narrowest read-side audit because it
exercises the same compact runtime-ID queue machinery with generated
single-beat `RID` completion, while avoiding `RLAST`, read-data consumers,
raw `ARLEN`, beat-count validation, multi-beat output banks, reserved static
ID exclusion, mixed dynamic/static request rules, or scoreboard semantics.

Read burst-last depth-3 remains one step wider because it has final-beat-only
dequeue semantics and raw non-final-beat preservation. Read-data over
depth-3 dynamic queues remains downstream of generated read queue behavior.
Mixed dynamic/static queues and dynamic scoreboards remain separate policy
surfaces.

Backend-language variants and SystemVerilog-to-Verilog portability remain
owned by `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`. FSMGen-owned
generation/lowering stays the default; external converters such as `sv2v`
are not selected dependencies in this IAL2 queue slice.

## Selected Next Leaf

`.484` should audit this exact candidate shape:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated single-beat RID completion
read-max-pending: at least 3
queue depth: 3
queue groups: one generated dynamic read single-beat group
```

The audit should decide whether the direct implementation can safely widen
the existing dynamic read single-beat queue builder to depth 3, or whether a
smaller prerequisite is needed first.

## Deferred Alternatives

Generated dynamic read burst-last depth-3 queues remain deferred until the
single-beat read audit records the read-side cardinality boundary.

Read-data, raw `ARLEN`, runtime validation, and multi-beat output banks over
depth-3 dynamic issue-order queues remain deferred until generated read
depth-3 response-demux behavior exists.

Mixed dynamic/static dynamic issue-order queues remain deferred because they
combine runtime-ID queue ordering with reserved static IDs and mixed request
conflict rules.

Dynamic scoreboards remain deferred. `scoreboard` is a distinct policy with
different storage and completion semantics from issue-order queues.

Arbitrary dynamic queue cardinality, direct backend behavior,
backend-language variants, external converter dependency selection, and VHDL
remain outside this IAL2 SystemVerilog-backed selector.

## Validation

The selector closed with documentation/continuity gates. A RAM-guarded
temporary read-depth3 schedule probe could not produce data because host
memory was already above the guard cutoff; no unguarded retry or cutoff raise
is selected by this slice.

`.484` owns any generated behavior probe, temporary candidate diagnostics,
code, test, sample, support-accounting, or report-surface update.

## Rollback

Rollback removes this selection note, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.482` generated
depth-3 write behavior, `.479` queue report surface, and `.477` generated
queue identity-recapture behavior remain unchanged.
