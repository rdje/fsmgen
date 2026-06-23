# AXI IAL2 Manager Mixed Dynamic/Static Read Response-Demux Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.274`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.275`, public contract selection for
bounded mixed dynamic/static read single-beat `RID` response-demux.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.273` post mixed dynamic/static write-demux selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md`
- `.272` mixed dynamic/static write `BID` behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md`
- `.271` mixed dynamic/static write contract selection.
- `.270` mixed dynamic/static response-demux readiness audit.
- `.268` multiple dynamic multi-beat output-bank behavior.
- `.255` multiple dynamic read burst-last/`RLAST` behavior.
- `.251` multiple dynamic read single-beat `RID` behavior.
- `.247` multiple dynamic write `BID` behavior.
- Current `response_demux.read` normalization, dynamic selected-ID/busy state,
  read-data coverage, report/residue wording, and support-detail prose in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- Focused validation caveats, support-accounting catalog, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Boundary

The generated dynamic read demux path supports all-dynamic selected read
families only. `_response_demux_dynamic_read_transaction` returns the current
fail-closed diagnostic when any selected read transaction is not dynamic:

```text
response_demux.read dynamic ID matching requires every read transaction to use dynamic IDs in this slice
```

For all-dynamic reads, the existing substrate is list-shaped:

- per-transaction dynamic selected-ID and busy state;
- admitted `ARID` capture from the read ID family request ID source;
- onehot0 same-cycle dynamic read request policy;
- active dynamic-ID uniqueness;
- raw `RID` active/unique-match assertions;
- generated completion pulses; and
- completion-active release assertions.

The shipped mixed dynamic/static write path proves the missing ownership model:
one dynamic transaction owns selected-ID/busy state, one concrete static
transaction owns static busy state, the static concrete ID is reserved away from
dynamic capture, mixed requests are onehot0, and raw `BID` response ownership is
proved with active/unique-match assertions.

## Readiness Findings

The lower substrate is ready for public contract selection, not direct
implementation.

Mixed dynamic/static read response ownership has the same core ambiguity as
mixed write: one raw `RID` can otherwise match both a static concrete read
transaction and an active dynamic read transaction whose captured ID equals that
static concrete ID. The write-side static-ID reservation rule is a suitable
first ownership model for reads: a dynamic read must not capture the selected
static concrete ID, and generated assertions should still prove active-match
and unique-match across dynamic and static read state.

Read response-demux also has extra read-only surfaces. A burst-last contract
must decide raw beat assertions versus final `RID && RLAST` completion,
`last_signal` ownership, and `RLAST` release timing. Read-data, raw `ARLEN`
capture, runtime beat-count/`RLAST` validation, and multi-beat output banks all
consume generated read completions or raw matched read beats. Those should not
be selected before the smaller mixed read single-beat ownership contract is
fixed.

## Selected First Read Shape

The first safe mixed read owner should be single-beat `RID` response-demux.

Single-beat `RID` is the narrowest read shape because it needs only the raw
accepted read response event and the read ID-family response ID signal. It does
not require `last_signal`, raw non-final beat accounting, read-data capture,
burst-length metadata, runtime beat-count validation, or per-beat output banks.

## Selected .275 Boundary

`.275` should select only the public contract for bounded mixed dynamic/static
read single-beat `RID` response-demux. It should decide and record:

- the exact public source shape and sample/support-accounting stem;
- whether the first shape requires exactly one dynamic read transaction and
  exactly one concrete static read transaction in the selected read family;
- whether existing `response-demux.read` syntax is reused unchanged with
  `response-scope single-beat` and generated transaction completion;
- how dynamic captured `ARID` values are prevented from colliding with the
  static concrete read ID;
- same-cycle dynamic/static read request policy;
- static busy-state ownership and release timing;
- whether same-cycle release-and-recapture remains deferred;
- response ownership when raw `RID` could otherwise match both dynamic and
  static read state;
- generated assertion and report vocabulary, including a future mode name such
  as `bounded_mixed_dynamic_static_read_rid_demux_contract`;
- focused diagnostics for unsupported burst-last, read-data, burst/runtime,
  multi-beat, read auto-ID, same-ID ordering, multiple mixed transactions, and
  partial transaction coverage cases;
- validation gates, rollback, docs, mdBook, and Knowledge Map impact; and
- explicit residue for mixed read burst-last/`RLAST`, scalar read-data,
  burst-length/runtime validation, multi-beat output banks, multiple mixed
  transactions, same-cycle request widening, release-and-recapture, dynamic
  same-ID queues, scoreboards, direct backend behavior, backend-language
  variants, and VHDL.

`.275` should not implement parser, generator, sample, support-accounting, test,
JSON, generated artifact, or HDL behavior. It should only select the future
public contract so a later implementation owner can change behavior with a
single unambiguous ownership model.

## Explicit Non-Goals

`.274` changes no behavior.

`.275` should not implement mixed dynamic/static read response-demux. It should
not select burst-last/`RLAST`, read-data, burst-length/runtime validation,
multi-beat output banks, multiple mixed write/read transactions, same-cycle
request widening, release-and-recapture, dynamic same-ID queues, scoreboards,
direct backend behavior, backend-language variants, or VHDL.

## Validation

Audit validation covers live docs, mdBook, Memory, Knowledge Map, diff hygiene,
and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.274` audit commit. Reverting it restores `.274` as the active
mixed dynamic/static read readiness-audit owner and removes the `.275`
contract-selection handoff.
