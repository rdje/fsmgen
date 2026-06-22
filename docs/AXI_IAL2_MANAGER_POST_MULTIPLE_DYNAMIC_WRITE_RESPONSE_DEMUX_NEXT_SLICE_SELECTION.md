# AXI IAL2 Manager Post Multiple Dynamic Write Response-Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.248`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.249`, readiness audit for
multiple dynamic read response-demux behavior after generated bounded multiple
dynamic write response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.247` multiple dynamic write response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`
- `.246` multiple dynamic write response-demux contract selection.
- `.245` multiple/mixed dynamic response-demux readiness audit.
- `.243` dynamic multi-beat read-data output-bank behavior.
- `.240` dynamic runtime-validation behavior and `.238` report-only dynamic
  raw-`ARLEN` behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last `RID && RLAST` response-demux behavior.
- `.227` dynamic read single-beat response-demux behavior.
- Current code/report surfaces in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`, especially the
  dynamic read response-demux normalizer, read-data coverage gate, dynamic
  capture/release helpers, response match helpers, assertion helpers, and
  report/residue text.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

`.247` moves the all-dynamic write-family multiple-transaction shape out of
dynamic residue. The remaining dynamic response-demux cluster is now:

```text
multiple dynamic read response-demux
mixed dynamic/static write or read response-demux
same-cycle request widening beyond onehot0
same-cycle release-and-recapture
dynamic same-ID ordering
dynamic same-ID queues and scoreboards
direct backend behavior outside the selected generated SystemVerilog path
backend-language variants
VHDL
```

The live read helper still rejects multiple dynamic reads before generated
artifacts: `_response_demux_dynamic_read_transaction` requires exactly one
dynamic read transaction and no additional read transactions. The read-data
coverage path also still requires exactly one dynamic read transaction and one
generated dynamic completion signal for dynamic read-data consumption.

## Rationale

Multiple dynamic read response-demux is the closest symmetric follow-up after
bounded multiple dynamic write response-demux, but it should be audited before
implementation. The write slice only had `BID` matching. The read slice must
account for two response scopes, `single_beat` and `burst_last`; optional
`RLAST` qualification; raw matched-read-beat counting; scalar read-data
capture; report-only and runtime `ARLEN` behavior; and multi-beat output-bank
capture from raw matched `RID` beats.

That coupling means a direct implementation choice must first decide whether
the first multiple dynamic read owner is response-demux-only, response-demux
plus scalar read-data preservation, burst-last only, single-beat only, or a
contract selector. It must also decide how the multiple write ambiguity policy
maps to read responses where one raw `RID` beat might match more than one
active dynamic read, and where the final completion pulse may be `RID &&
RLAST` while intermediate beats feed beat counters and output banks.

Mixed dynamic/static demux should wait until homogeneous multiple dynamic read
semantics are understood. Same-cycle widening, release-and-recapture,
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL are later owners because they depend on the response
ownership model selected for both write and read dynamic families.

## Selected .249 Boundary

`.249` should audit only:

- whether multiple dynamic read response-demux can be implemented directly or
  needs a public contract selector first;
- whether the first read owner should cover `single_beat`, `burst_last`, both
  scopes, or only response-demux without read-data expansion;
- how selected-ID/busy state, capture guards, active-ID uniqueness assertions,
  response active-match assertions, and response unique-match assertions map
  from write `BID` to read `RID` and optional `RLAST`;
- how raw matched-read-beat signals used by runtime validation and
  multi-beat output-bank capture remain unambiguous with multiple active
  dynamic reads;
- whether existing read-data coverage must stay single-dynamic in the first
  multiple-read demux slice or can be preserved for selected shapes;
- expected fail-closed diagnostics, report vocabulary, residue movement,
  public PPIF sample expectations, and focused `t/1438` coverage if an
  implementation owner is selected later; and
- docs, mdBook, Knowledge Map, rollback, and validation gates.

No parser, generator, PPIF sample, support-accounting, validation behavior,
generated artifact, test, schedule/check/semantic JSON, or HDL behavior
should change in `.249`.

## Explicit Non-Goals

`.249` should not implement multiple dynamic read demux, mixed dynamic/static
demux, same-cycle request widening, release-and-recapture, dynamic same-ID
ordering, queues, scoreboards, direct backend behavior, backend-language
variants, or VHDL. It should only decide the next owned boundary and record
enough evidence for a later safe implementation or contract-selection slice.

## Validation

Selector validation covers code review, live docs, mdBook, Memory, Knowledge
Map, and doctrine gates. No behavior changes.

## Rollback

Rollback is the `.248` selector commit. Reverting it restores `.248` as the
active selector after `.247` and removes the `.249` readiness-audit selection
record.
