# AXI IAL2 Manager Post Multiple Dynamic Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.269`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.270`, readiness audit for mixed
dynamic/static response-demux behavior after generated bounded multiple
dynamic multi-beat read-data output banks.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.268` multiple dynamic multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- `.267` multiple dynamic multi-beat contract selection:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_CONTRACT_SELECTION.md`
- `.266` multiple dynamic multi-beat readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md`
- `.264` multiple dynamic runtime beat-count/`RLAST` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`
- `.263` multiple dynamic report-only raw-`ARLEN` behavior.
- `.259` multiple dynamic scalar read-data behavior.
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior.
- `.251` multiple dynamic read single-beat response-demux behavior.
- `.247` multiple dynamic write response-demux behavior.
- `.244` post single-active dynamic multi-beat selector and `.245`
  multiple/mixed dynamic response-demux readiness precedent.
- Current implementation/report surfaces in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, especially dynamic
  response-demux normalizers, dynamic selected-ID/busy state helpers,
  response match expressions, report/residue wording, and unsupported dynamic
  transaction-ID detail.
- Focused dynamic validation surfaces in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, support
  accounting in `perl/FSM/Support/RegressionCorpus.pm`, README,
  `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Report Evidence

The `.268` public sample
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif`
now reports:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.residue = []
response_demux.mode = bounded_multi_dynamic_read_rid_rlast_demux_contract
response_demux.residue = [same_id_ordering]
```

The dynamic transaction-ID unsupported detail now says generated dynamic
write/read matching is supported for selected single-active and bounded
multiple all-dynamic write and read response-demux, scalar dynamic read-data,
multiple-dynamic report-only/runtime burst-length capture, and
runtime-assertion multi-beat output-bank capture.

The remaining dynamic cluster is:

```text
mixed dynamic/static response demux
same-cycle request widening beyond onehot0
same-cycle release-and-recapture
same-ID ordering
queues
scoreboards
direct backend behavior
backend-language variants
VHDL
```

## Rationale

After `.268`, the all-dynamic multiple dynamic path has write response-demux,
read single-beat response-demux, read burst-last/`RLAST` response-demux,
scalar read-data, report-only raw-`ARLEN` capture, runtime beat-count/`RLAST`
validation, and multi-beat output-bank behavior.

The next local response-ownership gap is mixed dynamic/static response-demux.
It is not safe to jump directly to dynamic same-ID queues, scoreboards, or
same-cycle widening first because those later behaviors depend on a settled
answer for how one raw response is owned when static concrete-ID matches and
dynamic captured-ID matches can coexist in the same family.

The mixed dynamic/static audit must decide whether the first safe shape is
write `BID`, read single-beat `RID`, read burst-last `RID && RLAST`, or a
smaller report/static cleanup or public contract-selection prerequisite. It
must also decide whether the first mixed shape requires generated assertions
that prevent dynamic captured IDs from colliding with static transaction IDs,
or whether some other deterministic ownership rule is required.

Same-cycle request widening and same-cycle release-and-recapture remain later
because the existing all-dynamic dynamic path deliberately uses onehot0
same-cycle request policy and separate release timing. Direct backend,
backend-language variants, and VHDL remain later lanes because the
SystemVerilog-backed IAL path still has local dynamic feature-completeness
residue.

## Selected .270 Boundary

`.270` should audit only:

- current fail-closed diagnostics for mixed dynamic/static write and read
  response-demux;
- whether response-demux state lists, dynamic capture/release helpers,
  response match expressions, static/concrete transaction states, and report
  projection can represent a mixed dynamic/static family safely;
- ambiguity cases where one raw response could match both a static concrete
  transaction and an active dynamic transaction;
- whether the first safe public shape should be write response-demux, read
  single-beat response-demux, read burst-last/`RLAST` response-demux, scalar
  read-data over a mixed boundary, a public contract selector, or another
  prerequisite;
- expected diagnostics, report vocabulary, residue movement, public sample
  names, support-accounting entries, focused test targets, rollback, docs,
  and Knowledge Map impact if a later implementation is selected; and
- explicit residue for same-cycle widening, release-and-recapture, dynamic
  same-ID queues, scoreboards, direct backend behavior, backend-language
  variants, and VHDL.

No parser, generator, PPIF sample, support-accounting, validation behavior,
generated artifact, test, schedule/check/semantic JSON, or HDL behavior
should change in `.270` unless the audit explicitly selects a later behavior
owner first.

## Explicit Non-Goals

`.269` changes no behavior.

`.270` should not implement mixed dynamic/static demux, same-cycle request
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, or VHDL. It should only decide
the next owned boundary and record enough evidence for a later safe
contract-selection or implementation slice.

## Validation

Selector validation covers live docs, mdBook, Memory, Knowledge Map, diff
hygiene, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.269` selector commit. Reverting it restores `.269` as the
active selector after `.268` and removes the `.270` readiness-audit
selection record.
