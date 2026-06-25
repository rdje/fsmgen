# AXI IAL2 Manager Post Dynamic Read Single-Beat Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.460`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.460` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.461`, readiness audit for generated
dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior
after the generated dynamic read single-beat `RID` queue behavior shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The selector read the `.459` generated dynamic read single-beat queue
behavior, `.458` contract selection, `.457` readiness audit, `.455`
generated dynamic write queue behavior, `.454` runtime-ID representation
selection, generated dynamic read single-beat response-demux and recapture
records, generated dynamic read burst-last `RID && RLAST` response-demux,
dynamic read `RLAST` transaction-ID capture, recapture, read-data, raw
`ARLEN`, runtime-validation, and multi-beat records, multiple all-dynamic read
response-demux and recapture records, generated dynamic reject mappings,
concrete read same-ID queue-head behavior records, parser/report/residue/
sample/support-accounting/code/test surfaces, validation and memory caveats,
README, ROADMAP_V2, mdBook, MEMORY, the active task tree, and Knowledge Map.

## Why Read Burst-Last Queue Readiness Is Next

The generated dynamic read single-beat queue path proves the compact runtime
ID slot representation, slot-local captured `ARID`, earliest matching `RID`,
same-cycle selected dequeue plus one enqueue, and generated `r0`/`r1`
completion outputs for exactly two all-dynamic read transactions. The adjacent
burst-last read queue cannot be copied directly from that behavior because it
must settle additional contract details first:

- Queue dequeue must happen only on the selected final `RID && RLAST` beat.
- Raw non-final `RID` beats need an explicit preservation or assertion policy.
- `response-demux.read` must define the required `response-scope burst-last`
  and one-bit `last-signal` boundary for dynamic issue-order queues.
- Active/unique response assertions must distinguish selected final matches
  from raw non-final response beats.
- The generated completion source must be safe for existing scalar last-beat
  read-data, raw `ARLEN`, runtime beat-count/`RLAST` validation, multi-beat
  output banks, and recapture consumers.
- Report vocabulary, residue movement, support accounting, sample ownership,
  diagnostics, validation gates, and rollback need to be chosen before any
  behavior-bearing change.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.461` is therefore the smallest safe next
owner. It will decide whether the direct burst-last dynamic queue behavior is
ready or whether a narrower prerequisite must land first.

## Deferred Work

The selector leaves read-data over generated dynamic queues, raw `ARLEN`
capture over generated dynamic queues, runtime beat-count/`RLAST` validation
over generated dynamic queues, multi-beat output banks over generated dynamic
queues, broader queue cardinality, mixed dynamic/static queues, dynamic
scoreboards, validation and memory retry follow-up, direct backend behavior,
backend-language variants, and VHDL as later exact-owner work.

## Validation

This is a docs-only selector. Closeout validation is limited to Knowledge Map
regeneration/check, mdBook build, docs relative-path audit, memory
architecture check, diff whitespace check, and doctrine gate.

## Rollback

Reverting the `.460` commit removes this selector, its Knowledge Map fact, and
the README/ROADMAP_V2/mdBook/task-tree/MEMORY frontier movement. No generated
behavior or user-facing PPIF semantics are affected.
