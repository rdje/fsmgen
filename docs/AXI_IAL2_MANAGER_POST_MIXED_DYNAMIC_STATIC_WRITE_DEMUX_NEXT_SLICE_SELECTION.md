# AXI IAL2 Manager Post Mixed Dynamic/Static Write Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.273`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.274`, readiness audit for mixed
dynamic/static read response-demux after generated bounded mixed
dynamic/static write `BID` response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.272` mixed dynamic/static write response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`
- `.271` mixed dynamic/static write response-demux contract selection:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`
- `.270` mixed dynamic/static response-demux readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `.268` multiple dynamic multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.247` multiple dynamic write response-demux behavior.
- Current response-demux normalization and fail-closed read diagnostics in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- Focused generator/support-accounting coverage, README, `ROADMAP_V2.md`,
  mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

The shipped mixed dynamic/static behavior is currently write-only. The public
sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`
uses existing `response-demux.write` syntax with one dynamic write transaction
and one concrete static write transaction. Static concrete IDs are reserved
away from dynamic capture so one raw `BID` cannot legally match both owners.

The read side still intentionally fails closed when a selected read family
mixes dynamic and static/concrete transaction IDs. The current diagnostic is:

```text
response_demux.read dynamic ID matching requires every read transaction to use dynamic IDs in this slice
```

The all-dynamic read path already covers single-beat `RID`, burst-last
`RID && RLAST`, scalar read-data, report-only raw-`ARLEN`, runtime
beat-count/`RLAST` validation, and multi-beat output banks. That does not by
itself define mixed dynamic/static read ownership.

## Rationale

Mixed dynamic/static read response ownership is the next local response-demux
gap after mixed write `BID` behavior shipped. It should be audited before
multiple mixed write transactions, same-cycle widening, release-and-recapture,
dynamic same-ID queues, or scoreboards because all of those later behaviors
depend on deterministic ownership when dynamic captured IDs and static
concrete IDs can coexist.

The first read-side implementation is not safe to select directly in `.273`.
Unlike write `BID`, read response-demux has several coupled shapes:

- single-beat `RID` completion;
- burst-last `RID && RLAST` completion;
- scalar read-data capture over generated completions;
- raw `ARLEN` burst-length capture and runtime beat-count/`RLAST`
  validation; and
- multi-beat output-bank lane capture from raw matched read beats.

The audit must decide whether the first safe mixed read owner is single-beat
`RID`, burst-last `RID && RLAST`, a report/static cleanup, public contract
selection, or another smaller prerequisite. It must also decide whether the
write-side static-ID reservation rule generalizes directly to read or whether
read-side `RLAST`/read-data coupling needs a narrower first contract.

VHDL and backend-language variants remain deferred because the
SystemVerilog-backed IAL path still has protocol-intent feature-completeness
residue, and `docs/decisions/0018` keeps IAL contracts
backend-language-neutral.

## Selected .274 Boundary

`.274` should audit only:

- current fail-closed diagnostics for mixed dynamic/static read
  response-demux;
- whether read selected-ID/busy state, static/concrete ownership state,
  response match expressions, `RLAST` handling, read-data completion
  validity, burst-length/runtime validation, and multi-beat output-bank
  helpers can represent a bounded mixed read family safely;
- ambiguity cases where one raw `RID` or `RID && RLAST` beat could match both
  a static concrete transaction and an active dynamic transaction;
- whether the first safe read shape should be single-beat `RID`, burst-last
  `RID && RLAST`, scalar read-data over mixed demux, burst-length/runtime,
  multi-beat output banks, a public contract selector, report/static cleanup,
  or another prerequisite;
- expected diagnostics, report vocabulary, residue movement, public sample
  names, support-accounting entries, focused test targets, rollback, docs,
  and Knowledge Map impact if a later contract or implementation is selected;
  and
- explicit residue for multiple mixed transactions, same-cycle widening,
  release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL.

No parser, generator, PPIF sample, support-accounting, validation behavior,
generated artifact, test, schedule/check/semantic JSON, or HDL behavior should
change in `.274` unless the audit explicitly selects a later behavior owner
first.

## Explicit Non-Goals

`.273` changes no behavior.

`.274` should not implement mixed read demux. It should not widen read-data,
burst-length/runtime validation, multi-beat output banks, multiple mixed write
transactions, same-cycle request policy, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, or VHDL. It should only decide the next owned boundary and record
enough evidence for a later safe contract-selection or implementation slice.

## Validation

Selector validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.273` selector commit. Reverting it restores `.273` as the
active selector after `.272` and removes the `.274` readiness-audit
selection.
