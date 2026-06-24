# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Burst-Length Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.353`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.353` ships generated report-only
raw-`ARLEN` burst-length capture over the generated
two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID && RLAST` response-demux and scalar last-beat read-data boundary selected
by `.352`.

The shipped public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif
```

It is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length
```

with coverage:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli
```

and focused behavior label:

```text
mixed_dynamic_static_read_data_multi_dynamic_burst_length
```

## Generated Behavior

The implementation extends only the `.350` scalar last-beat read-data shape:

- dynamic read transactions `r0` and `r1`;
- concrete static read transaction `r2` with static `RID` value `3`;
- generated mixed dynamic/static burst-last response-demux completion source
  `generated_multi_mixed_dynamic_static_read_demux_last_beat`;
- scalar last-beat `RDATA`/`RRESP` capture for `r0`, `r1`, and `r2`; and
- `burst-length` metadata with `source arlen`, signal `axi0_arlen` width 8,
  `axlen-plus-one` encoding, request capture, `max-beats 16`, and
  `validation report-only`.

Generated artifacts add:

- input `axi0_arlen`;
- raw-`ARLEN` storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- request-guarded raw-`ARLEN` capture rules
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
  `axi0_r2_burst_length_capture`; and
- report fields listing generated burst-length inputs, storage, capture rules,
  validation mode `report_only`, and explicit runtime-validation residue.

The scalar last-beat payload capture remains guarded by the generated
final-beat completion pulses. Report-only raw-`ARLEN` capture does not create
expected-beat storage, read-beat counters, or runtime `RLAST` assertions.

## Boundaries

The new admission is exact: it requires generated
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, capture-scope
`last-beat`, exactly two dynamic read transactions plus one concrete static
read transaction, and `validation report-only`.

These remain fail-closed exact-owner residue:

- runtime beat-count/`RLAST` validation over this two-dynamic-plus-one-static
  raw-`ARLEN` shape;
- multi-beat output banks over this shape;
- single-beat read-data over `.344`;
- broader mixed dynamic/static cardinalities;
- same-cycle request widening and same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants and VHDL;
- profile aliases, queued/blocking policy, and full AXI manager behavior.

## Validation

Validation for `.353` included:

- syntax checks for touched Perl modules and focused tests;
- guarded schedule JSON for the new sample at the default host cutoff;
- guarded strict semantic JSON for the new sample with the documented
  `--host-max-pct 93` retry after the default host-memory cutoff stopped
  heavier JSON/check probes;
- guarded partial focused `t/1438` behavior with CLI JSON skipped, which
  passed all parser/report/ISF/FSM assertions before the host-memory guard
  stopped the isolated HDL inspection step at the 93% cutoff;
- guarded `t/248-regression-corpus-accounting.t`, 4568 tests passed;
- guarded schedule-preservation probes for `.350`, `.347`, `.344`,
  two-static report-only raw-`ARLEN`, and representative all-dynamic
  report-only raw-`ARLEN` samples; and
- a guarded negative runtime-validation variant probe, which rejected the
  two-dynamic-plus-one-static runtime shape at the bounded coverage diagnostic.

The direct strict check JSON probe, default generation probe, direct HDL
verification probe, and isolated HDL assertion probe were stopped by the host
memory guard before completion and were not forced above the documented 93%
retry profile.

## Next Frontier

`.354` is the next exact owner: runtime beat-count/`RLAST` validation readiness
over the shipped two-dynamic-plus-one-static report-only raw-`ARLEN` scalar
last-beat read-data boundary.
