# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.350`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.350` ships scalar last-beat
`RDATA`/`RRESP` capture over the generated two-dynamic-plus-one-static mixed
dynamic/static read burst-last `RID`/`RLAST` response-demux selected by
`.349`.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif
```

It uses dynamic read transactions `r0` and `r1`, static read transaction `r2`
with concrete ID `3`, generated response-demux completion over
`axi0_read_complete`, `axi0_rid`, and `axi0_rlast`, and scalar last-beat
payload capture from `axi0_rdata`/`axi0_rresp`.

## Generated Behavior

The generated response-demux behavior remains the `.347` contract:

- selected dynamic ID/busy state for `r0` and `r1`;
- static busy state for `r2`;
- onehot0 mixed request policy;
- dynamic request/active selected-ID uniqueness checks;
- static concrete-ID exclusion for `4'd3`;
- raw `RID` active/unique response assertions independent of `RLAST`; and
- generated completion pulses only on final `RID && RLAST` matches.

The new `.350` read-data behavior adds three scalar capture rules:

```text
axi0_r0_read_data_capture
axi0_r1_read_data_capture
axi0_r2_read_data_capture
```

Each rule is guarded by that transaction's generated final-beat completion
pulse and assigns the shared read payload/status inputs to the selected scalar
last-beat outputs:

```text
axi0_r0_last_rdata / axi0_r0_last_rresp
axi0_r1_last_rdata / axi0_r1_last_rresp
axi0_r2_last_rdata / axi0_r2_last_rresp
```

The read-data capture rules do not re-match `RID` or `RLAST`; matching remains
owned by the response-demux completion pulses.

## Report Surface

Schedule JSON reports the response-demux mode as
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, with
dynamic transactions `r0`/`r1`, static transaction `r2`, completion source
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, completion
semantics `matched_dynamic_or_static_concrete_id_and_last_signal`, one-bit
last signal `axi0_rlast`, and static exclusion `4'd3`.

The read-data report is `bounded_last_beat_read_data_contract` with completion
validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
generated inputs `axi0_rdata` and `axi0_rresp`, transactions `r0`, `r1`, `r2`,
and generated rules `axi0_r0_read_data_capture`,
`axi0_r1_read_data_capture`, and `axi0_r2_read_data_capture`.

The read-data residue remains explicit:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
arlen_or_beat_count_validation
```

## Validation

The `.350` slice passed syntax checks for the touched Perl modules and focused
tests, strict check JSON for the new public sample, schedule JSON, semantic
JSON, default SystemVerilog emission, `--verify-hdl`, the focused `t/1438`
behavior with `FSMGEN_DYNAMIC_SKIP_CLI_JSON=1`, and `t/248` support accounting.

Preservation checks passed for the `.347` burst-last demux sample, the `.344`
single-beat two-dynamic/one-static sibling, the two-static scalar last-beat
read-data sample, and a representative multiple all-dynamic scalar last-beat
read-data sample. The three-static scalar last-beat read-data strict-check
preservation probe hit the default host-memory cutoff and was not forced
unbounded; its guarded schedule JSON preservation probe passed.

## Boundaries

`.350` does not add single-beat read-data over `.344`, raw `ARLEN`
burst-length capture, runtime beat-count/`RLAST` validation, multi-beat output
banks, broader mixed cardinalities, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior, backend-language
variants, VHDL behavior, profile aliases, queued/blocking policy, or full AXI
manager behavior.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.351`, a selector
for report-only raw-`ARLEN` burst-length readiness over this shipped scalar
last-beat read-data boundary.
