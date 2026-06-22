# AXI IAL2 Manager Post Dynamic Read ID Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.228` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.228`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.229`, readiness audit for dynamic
read burst-last/`RLAST` transaction-ID capture and response matching.

Do not implement dynamic read burst-last behavior directly in `.228`. The
single-beat dynamic read path shipped by `.227` proves the admitted `ARID`
capture, selected-ID/busy state, `RID` match, generated completion, release,
assertion, and report substrate for one dynamic read transaction. The next
read-side dynamic surface changes the response semantics: the generated
completion must be last-beat qualified and must settle how `RLAST` participates
with the captured dynamic ID before any parser, generator, public sample,
support accounting, validation, generated artifact, test, or HDL behavior
changes.

## Evidence Read

The selector read:

- `.227` generated bounded single-beat dynamic read behavior.
- `.226` dynamic read public contract selection and `.225` readiness audit.
- `.223` generated dynamic write behavior and `.219` dynamic transaction-ID
  metadata behavior.
- Existing non-dynamic read response-demux single-beat and burst-last/`RLAST`
  behavior records.
- Existing read-data, burst-length, runtime-validation, and multi-beat output
  behavior records that depend on read response-demux completion semantics.
- Support-accounted dynamic read/write samples, README, `ROADMAP_V2.md`,
  mdBook backlog, task tree, Memory, and Knowledge Map.

## Why The Next Owner Is An Audit

Dynamic read burst-last/`RLAST` is not just the single-beat `.227` rule with an
extra input. The audit must first pin down:

- whether the public shape reuses `response-demux.read` with
  `response-scope burst-last` and `last-signal`;
- whether the raw response event is a beat-valid transfer and the generated
  completion is exactly `response_event && RLAST && RID == captured_id`;
- how the single-active dynamic busy bit behaves across all non-last beats;
- which assertions guard raw responses while inactive, mismatched `RID`,
  missing `RLAST`, early `RLAST`, and completion while inactive;
- how the report vocabulary relates to
  `bounded_dynamic_read_rid_demux_contract` and existing generated
  burst-last/`RLAST` modes;
- how read-data, raw `ARLEN` capture, beat-count/runtime validation, and
  multi-beat output-bank behavior remain explicit residue until selected.

The selector found no immediate report/static/support cleanup prerequisite
after `.227`. The shipped dynamic read behavior document, task tree, README,
roadmap, mdBook, and Knowledge Map already identify burst-last/`RLAST`,
read-data, burst/runtime, multiple/mixed, same-cycle, same-ID, queue/scoreboard,
direct-backend, and VHDL boundaries as deferred.

## Scope For `.229`

`.229` is audit-only. It should decide whether the next owner is:

- public contract selection for dynamic read burst-last/`RLAST`;
- direct bounded implementation after the audit, if no new contract or lower
  substrate prerequisite is needed;
- a report/static cleanup prerequisite;
- a lower IAL1/IAL0/SystemVerilog prerequisite; or
- a narrower selector.

The audit must record response scope, last-signal ownership, admitted-request
capture timing, selected-ID/busy lifetime, raw response/`RID`/`RLAST`
completion semantics, read-data and burst/runtime interaction, assertions,
diagnostics, report vocabulary, generated `.isf`/`.fsm`/HDL boundaries,
validation gates, rollback, documentation, Knowledge Map impact, and residue.

## Non-Goals

`.228` changes no parser, generator, PPIF sample, support-accounting catalog,
validation, generated artifact, test, or HDL behavior.

`.229` must also remain audit-only unless it explicitly creates a later owner.
It must not implement dynamic read burst-last behavior, dynamic read-data
routing, burst-length capture, runtime validation, multi-beat output banks,
multiple dynamic read transactions, mixed dynamic/static read demux,
same-cycle release-and-recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, or VHDL behavior.

## Validation

Selector closeout validation for `.228`:

```sh
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any later behavior owner must add focused generator/PPIF tests,
support-accounting updates, schedule/check/semantic JSON probes, generated
artifact checks, and HDL reachability for its selected public sample.

## Rollback

Rollback for `.228` is limited to this selector record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No behavior-bearing file is part of this slice.
