# AXI IAL2 Manager Post Mixed Dynamic/Static Read Demux Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.277`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.278`, readiness audit for bounded
mixed dynamic/static read burst-last `RID && RLAST` response-demux after
generated bounded mixed dynamic/static read single-beat `RID` response-demux.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.276` mixed dynamic/static read single-beat `RID` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md`
- `.275` mixed dynamic/static read single-beat `RID` response-demux contract:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`
- `.274` mixed dynamic/static read response-demux readiness audit:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`
- `.272` mixed dynamic/static write `BID` response-demux behavior.
- `.255` multiple dynamic read burst-last `RID && RLAST` response-demux
  behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.231` single-active dynamic read burst-last `RID && RLAST` response-demux
  behavior.
- Current mixed dynamic/static read single-beat state, assertion, report, and
  fail-closed burst-last/read-data normalization in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- Focused dynamic validation surfaces, support-accounting catalog, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

`.276` ships exactly one mixed read shape:

```text
response-demux.read response-scope single-beat
one dynamic read transaction
one concrete static read transaction
generated completion
```

The generated behavior captures the dynamic transaction's admitted `ARID`,
tracks dynamic and static busy state, reserves the static concrete ID away
from dynamic capture, and matches one raw single-beat `RID` response against
either the active dynamic ID or the active static concrete ID.

Mixed dynamic/static read burst-last remains intentionally fail-closed. The
current mixed branch accepts only `response-scope single-beat`; `RLAST`,
non-final read beats, read-data capture, raw `ARLEN`, beat-count validation,
and multi-beat output banks remain separate residue.

## Rationale

The next local read-side gap is burst-last `RID && RLAST`, not read-data or
burst/runtime behavior. Read-data, raw `ARLEN`, runtime beat-count validation,
and multi-beat output banks all depend on a settled generated completion or
matched-beat boundary. For mixed dynamic/static read ownership, that boundary
must first prove how final read beats are identified without allowing a raw
`RID` match on an intermediate beat to complete a transaction early.

The existing all-dynamic dynamic path already has precedents for burst-last
single-active and multiple-dynamic response-demux, including `last-signal`
metadata, `RLAST`-gated completion, and last-beat report vocabulary. The
mixed dynamic/static path also now has static-ID reservation and onehot0
mixed read request assertions from `.276`. The audit must decide whether
those two precedents compose directly or whether a narrower public contract
selection or helper prerequisite is required first.

Same-cycle request widening, release-and-recapture, multiple mixed
transactions, dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain later because all of them rely on
the response-ownership and release boundary being settled for the simpler
single-active mixed read family first.

## Selected .278 Boundary

`.278` should audit only:

- current fail-closed diagnostics for mixed dynamic/static read burst-last
  response-demux;
- whether the `.276` dynamic selected-ID/busy state, static busy state,
  static-ID reservation, onehot0 mixed read request assertion, response
  active/unique-match assertions, and completion-active release assertions can
  extend to `RID && RLAST` without ambiguity;
- whether existing all-dynamic burst-last `last-signal`, response-scope,
  matched-read-beat, report, and residue helpers can represent the mixed
  one-dynamic plus one-concrete-static read family;
- whether the next owner after the audit should be public contract selection,
  direct generated behavior, report/static cleanup, or a smaller prerequisite;
- expected diagnostics, report vocabulary, public sample/support-accounting
  stem, focused validation gates, rollback, docs, Knowledge Map impact, and
  explicit residue; and
- explicit non-goals for read-data over mixed demux, burst-length/runtime
  behavior, multi-beat output banks, multiple mixed transactions, same-cycle
  widening, release-and-recapture, queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL.

No parser, generator, PPIF sample, support-accounting, validation behavior,
generated artifact, test, schedule/check/semantic JSON, or HDL behavior should
change in `.278` unless the audit explicitly selects a later implementation
owner first.

## Explicit Non-Goals

`.277` changes no behavior.

`.278` should not implement mixed read burst-last demux. It should not add
read-data, burst-length/runtime validation, multi-beat output banks, multiple
mixed transactions, same-cycle request widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, or VHDL. It should only decide the next owned
boundary and record enough evidence for a later safe contract-selection or
implementation slice.

## Validation

Selector validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.277` selector commit. Reverting it restores `.277` as the
active selector after `.276` and removes the `.278` readiness-audit
selection record.
