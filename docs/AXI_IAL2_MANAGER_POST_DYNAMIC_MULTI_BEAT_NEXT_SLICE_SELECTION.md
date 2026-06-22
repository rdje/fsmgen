# AXI IAL2 Manager Post Dynamic Multi-Beat Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.244`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.245`, readiness audit for
multiple/mixed dynamic response-demux behavior after generated dynamic
multi-beat read-data output banks.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.243` dynamic multi-beat behavior:
  `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- `.242` dynamic multi-beat readiness audit.
- `.240` dynamic runtime-validation behavior and `.238` report-only dynamic
  raw-`ARLEN` behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last `RID && RLAST` response-demux behavior.
- `.227` dynamic read single-beat response-demux behavior.
- `.223` dynamic write `BID` response-demux behavior.
- `.219` dynamic transaction-ID metadata behavior.
- Current code/test surfaces in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`,
  `t/1437-axi-ial2-manager-capacity-status-generator.t`, and
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`.
- README, `ROADMAP_V2.md`, mdBook, task tree, Memory, and Knowledge Map.

## Current Report Evidence

The `.243` public sample
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif` now
reports:

```text
response_demux.residue: [same_id_ordering]
read_data.residue: []
```

Its unsupported dynamic transaction-ID detail says the generated dynamic
family now supports single-active write response demux, read single-beat
response demux, read burst-last response demux, scalar dynamic read-data,
report-only and runtime-assertion dynamic burst-length capture, and
runtime-assertion raw-`ARLEN` multi-beat dynamic read-data output banks.

The remaining dynamic cluster is:

```text
multiple dynamic read/write transactions
mixed dynamic/static response demux
same-cycle recapture
same-ID ordering
queues
scoreboards
HDL behavior outside the selected dynamic write/read shapes
```

## Rationale

After `.243`, the selected single-active dynamic read path has scalar
single-beat, scalar last-beat, report-only burst-length, runtime validation,
and multi-beat output-bank behavior. The next local residue is no longer
read-data routing; it is response-demux ownership for more than one dynamic
transaction and for mixed dynamic/static families.

Multiple/mixed dynamic response-demux readiness should come before dynamic
same-ID ordering, queues, and scoreboards because those later behaviors need
a clear dynamic response ownership model: per-transaction selected-ID and
busy state, simultaneous request capture rules, response-to-transaction
priority or exclusivity, release timing, same-cycle recapture semantics,
diagnostics, and report vocabulary. Direct backend and VHDL remain later
lanes because the SystemVerilog-backed IAL path still has local dynamic
feature-completeness residue.

## Selected .245 Boundary

`.245` should audit only:

- whether the next behavior owner should be multiple dynamic write response
  demux, multiple dynamic read response demux, mixed dynamic/static response
  demux, same-cycle recapture semantics, or a public contract selector first;
- whether the existing generated selected-ID/busy storage and dynamic
  capture/release helpers can generalize to per-transaction dynamic state;
- how response matching stays deterministic when multiple dynamic
  transactions can observe the same response family;
- whether request-side mutual exclusion, onehot assertions, or a narrower
  single-family first slice is required;
- which diagnostics should remain fail-closed until implementation;
- expected schedule/check/semantic JSON report movement and residue cleanup;
- focused `t/1438` coverage and public PPIF sample expectations if direct
  implementation is selected later; and
- docs, mdBook, Knowledge Map, rollback, and validation gates.

No parser, generator, PPIF sample, support-accounting, validation behavior,
generated artifact, test, schedule/check/semantic JSON, or HDL behavior
should change in `.245`.

## Explicit Non-Goals

`.245` should not implement multiple/mixed dynamic demux, same-cycle
recapture, dynamic same-ID ordering, queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL. It should only decide the next
owned boundary and record enough evidence for a later safe implementation or
contract-selection slice.

## Validation

Selector validation covered the fresh `.243` schedule report, live docs,
mdBook, Memory, Knowledge Map, and doctrine gates. No behavior changed.

## Rollback

Rollback is the `.244` selector commit. Reverting it restores `.244` as the
active selector after `.243` and removes the `.245` readiness-audit selection
record.
