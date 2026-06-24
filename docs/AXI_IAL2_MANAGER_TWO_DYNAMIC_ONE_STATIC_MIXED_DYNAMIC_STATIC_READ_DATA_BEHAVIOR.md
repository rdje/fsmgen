# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.361`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.361` ships scalar single-beat
`RDATA`/`RRESP` capture over the generated two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` response-demux shipped by `.344`.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

It uses dynamic read transactions `r0` and `r1`, static read transaction `r2`
with concrete ID `3`, generated response-demux completion over
`axi0_read_complete` and `axi0_rid`, and scalar payload capture from
`axi0_rdata`/`axi0_rresp`.

## Generated Behavior

The generated response-demux behavior remains the `.344` contract:

- selected dynamic ID/busy state for `r0` and `r1`;
- static busy state for `r2`;
- onehot0 mixed request policy;
- dynamic request/active selected-ID uniqueness checks;
- static concrete-ID exclusion for `4'd3`;
- generated completion pulses on matched single-beat `RID` responses; and
- no `RLAST`, `ARLEN`, burst-length, runtime-validation, or multi-beat payload
  state.

The `.361` read-data behavior adds shared generated inputs:

```text
axi0_rdata
axi0_rresp
```

and per-transaction scalar outputs:

```text
axi0_r0_rdata / axi0_r0_rresp
axi0_r1_rdata / axi0_r1_rresp
axi0_r2_rdata / axi0_r2_rresp
```

The generated capture rules are:

```text
axi0_r0_read_data_capture
axi0_r1_read_data_capture
axi0_r2_read_data_capture
```

Each rule is guarded by that transaction's generated completion pulse. The
read-data path does not re-match `RID`; matching remains owned by the
response-demux completion pulses.

## Report Surface

Schedule JSON reports the response-demux mode as
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, with dynamic
transactions `r0`/`r1`, static transaction `r2`, completion source
`generated_multi_mixed_dynamic_static_read_demux`, completion semantics
`matched_dynamic_or_static_concrete_id_single_beat`, and static exclusion
`4'd3`.

The read-data report is `bounded_single_beat_read_data_contract` with
completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
generated inputs `axi0_rdata` and `axi0_rresp`, transactions `r0`, `r1`, `r2`,
and generated rules `axi0_r0_read_data_capture`,
`axi0_r1_read_data_capture`, and `axi0_r2_read_data_capture`.

The read-data residue remains explicit:

```text
rlast_completion
bursts
multi_beat_read_data_reassembly
```

## Validation

The `.361` slice passed syntax checks for the touched Perl modules and focused
tests, guarded schedule JSON for the new public sample at the documented 93%
RAM profile after the default 88% host-memory cutoff stopped before useful
work, and guarded `t/248` support accounting with 4599 tests. Guarded strict
check JSON, semantic JSON, default-HDL, and focused `t/1438` behavior with
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1` stopped during HDL inspection at the 93% RAM
cutoff and was not forced unbounded.

## Boundaries

`.361` does not add burst-last/last-beat siblings, raw `ARLEN` burst-length
capture, runtime beat-count/`RLAST` validation, multi-beat output banks,
broader mixed cardinalities, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior, backend-language
variants, VHDL behavior, profile aliases, queued/blocking policy, or full AXI
manager behavior.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.362`, a selector
for the next IAL2 feature-completeness slice after this single-beat read-data
sibling shipped.
