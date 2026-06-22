# AXI IAL2 Manager Post Dynamic Read RLAST Next Slice Selection

Status: selector for `IAL2-FEATURE-COMPLETENESS-FRONTIER.232` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.232`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.233`, readiness audit for dynamic
read-data routing over generated single-active dynamic read response-demux.

Do not implement dynamic read-data routing directly in `.232`. The shipped
dynamic read response-demux family now has two generated read-side shapes:

- `.227` single-beat dynamic read response-demux captures admitted `ARID`,
  stores selected-ID/busy state, matches raw `RID == captured_id`, pulses the
  generated read completion, and releases busy.
- `.231` burst-last dynamic read response-demux reuses the same selected-ID and
  busy substrate but completes only on raw read response plus
  `RID == captured_id` plus `RLAST`.

That substrate is enough to make read-data routing the next promising feature
surface, but the current generator intentionally rejects dynamic read IDs with
`read_data.read`. The next owner must audit how the existing read-data
capture/report machinery should consume generated dynamic completions before
any behavior-bearing change.

## Evidence Read

The selector read or probed:

- Dynamic transaction-ID metadata behavior from `.219`.
- Dynamic write `BID` response-demux behavior from `.223`.
- Dynamic read single-beat `RID` response-demux behavior from `.227`.
- Dynamic read burst-last `RID && RLAST` response-demux behavior from `.231`.
- Current PPIF `response-demux` and `read-data` syntax in
  `perl/FSM/Adapter/IAL2/PPIF.pm`.
- The dynamic read-data interaction gate and read-data coverage helpers in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`.
- Representative non-dynamic read-data, burst-length, runtime-validation, and
  multi-beat precedents.
- Focused tests, public PPIF samples, support accounting, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.
- Direct schedule/check/semantic probes for the shipped dynamic read RLAST
  sample, confirming `bounded_dynamic_read_rid_rlast_demux_contract`,
  matched-ID-and-last completion semantics, and fail-closed dynamic read-data
  residue.

## Why The Next Owner Is An Audit

Dynamic read-data is not only a new output assignment. The audit must first
settle:

- whether the first generated boundary covers single-beat dynamic read-data,
  last-beat dynamic read-data, or both;
- whether read-data captures from the generated dynamic transaction completion,
  from the raw response event plus dynamic match, or from another internal
  signal boundary;
- how data/status capture names, reset behavior, and generated reports align
  with existing auto-ID and concrete queue-head read-data paths;
- whether `read_data.read completion-source response-demux` should be accepted
  with dynamic read transactions only when the same read family has one
  selected single-active dynamic response-demux transaction;
- which diagnostics should explain unsupported burst-length/runtime
  validation, multi-beat outputs, multiple dynamic reads, mixed dynamic/static
  demux, same-cycle recapture, same-ID ordering, queues, scoreboards, direct
  backend behavior, and VHDL;
- which public sample, support-accounting entry, focused tests, generated
  artifact probes, and HDL reachability checks would be required by a later
  implementation owner.

The selector found no stale report/static/support cleanup prerequisite that
should run before this audit. The shipped behavior records and live reports
already identify dynamic read-data and burst/runtime/multi-beat follow-ons as
explicit residue.

## Scope For `.233`

`.233` is audit-only. It should decide whether the next owner is:

- direct bounded implementation of dynamic read-data routing for one generated
  single-beat dynamic read response-demux family;
- direct bounded implementation of dynamic last-beat read-data over the
  generated burst-last `RID && RLAST` dynamic read response-demux family;
- a public contract/report selection step before behavior changes;
- a lower cleanup prerequisite in read-data coverage, completion projection,
  support accounting, or diagnostics; or
- a narrower selector.

The audit must record public syntax expectations, generated completion
consumption, selected-ID/busy interactions, data/status capture, report keys,
diagnostics, sample/support-accounting boundaries, validation gates, rollback,
documentation, Knowledge Map impact, and explicit residue.

## Non-Goals

`.232` changes no parser, generator, PPIF sample, support-accounting catalog,
validation, generated artifact, test, or HDL behavior.

`.233` must also remain audit-only unless it explicitly creates a later owner.
It must not implement dynamic read-data routing, burst-length capture, runtime
validation, multi-beat output banks, multiple dynamic read/write transactions,
mixed dynamic/static demux, same-cycle release-and-recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, or VHDL behavior.

## Validation

Selector closeout validation for `.232`:

```sh
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
scripts/check_doctrines.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

Any later behavior owner must add focused parser/generator tests,
support-accounting updates, schedule/check/semantic JSON probes, generated
artifact checks, and HDL reachability for its selected public sample.

## Rollback

Rollback for `.232` is limited to this selector record, task-tree frontier
movement, README, `ROADMAP_V2.md`, mdBook, Memory, and Knowledge Map updates.
No behavior-bearing file is part of this slice.
