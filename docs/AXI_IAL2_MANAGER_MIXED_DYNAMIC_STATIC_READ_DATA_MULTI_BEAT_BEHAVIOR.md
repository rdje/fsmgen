# AXI IAL2 Manager Mixed Dynamic/Static Multi-Beat Read-Data Behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.291`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.291` ships generated mixed
dynamic/static multi-beat read-data output banks over generated mixed
dynamic/static read burst-last response-demux and runtime beat-count/`RLAST`
validation.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
```

This is the multi-beat sibling of the `.289` runtime-validation sample. It
keeps exactly one dynamic read transaction and one concrete static read
transaction, generated mixed `RID && RLAST` response-demux, request-captured
raw `ARLEN`, expected-beat storage, read-beat counters, and runtime
assertions, then replaces scalar last-beat `RDATA`/`RRESP` outputs with
per-beat output banks.

## Source Shape

The supported source shape requires:

- exactly one read transaction with `(id dynamic)`;
- exactly one read transaction with a concrete static ID;
- `response-demux.read` with `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation.policy
  worst-observed`, and `interleaving multi-beat-by-rid`;
- `burst-length` uses `source arlen`, width-8 `axi0_arlen`,
  `axlen-plus-one`, request capture, `max-beats 1..256`, and
  `validation runtime-assertion`; and
- every covered transaction supplies a data output prefix, status output
  prefix, scalar status aggregate output, valid-mask output, and length
  output.

Other mixed dynamic/static cardinalities remain fail-closed.

## Generated Behavior

For the public two-transaction, 16-beat sample, FSMGen emits shared generated
inputs for `RDATA`, `RRESP`, and `ARLEN`, then emits per-transaction state:

```text
axi0_r0_arlen_q
axi0_r1_arlen_q
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
```

Each transaction request initializes that transaction's output bank: data
lanes to zero, status lanes to zero, scalar aggregate status to zero, valid
mask to zero, and length output to zero. The same request captures raw
`ARLEN`, initializes expected beats to `ARLEN + 1`, and clears the
transaction's read-beat counter.

Lane capture uses raw accepted read beats. The dynamic transaction captures a
lane when `axi0_read_complete` is true, the dynamic transaction is busy, and
`axi0_rid` matches `axi0_r0_dynamic_id_q`. The static transaction captures a
lane when `axi0_read_complete` is true, static busy state is active, and
`axi0_rid` matches the reserved concrete ID `4'd3`. Lane capture is indexed
by the pre-increment read-beat counter and is not gated by `RLAST`; the final
`RID && RLAST` beat remains the response-demux completion/release boundary.

The public sample emits:

- 32 generated `RDATA` lane outputs, 16 for `r0` and 16 for `r1`;
- 32 generated `RRESP` lane outputs, 16 for `r0` and 16 for `r1`;
- valid-mask outputs `axi0_r0_beat_valid` and `axi0_r1_beat_valid`;
- length outputs `axi0_r0_read_beats` and `axi0_r1_read_beats`;
- scalar worst-observed status outputs `axi0_r0_rresp` and
  `axi0_r1_rresp`;
- per-lane capture rules for each bounded beat of each transaction;
- per-transaction output-bank init, burst-length capture, beat-count init,
  beat-count increment, and scalar status aggregate rules; and
- four runtime assertions per transaction: `arlen_within_max`,
  `read_beat_before_expected_count`, `rlast_on_expected_beat`, and
  `expected_final_beat_has_rlast`.

Scalar status aggregation uses worst-observed `RRESP`: each aggregate starts
at zero at request time and updates when a matched beat carries a numerically
larger two-bit response status.

## Report Contract

Schedule/check/semantic JSON reports the read-data shape as:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.read.completion_validity =
  generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.capture_scope = multi_beat
read_data.read.status_policy = per_beat
read_data.read.status_aggregation = worst_observed
read_data.read.interleaving_policy = multi_beat_by_rid
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_match_source = response_demux_matched_read_beat
read_data.read.beat_count_match_source = response_demux_matched_read_beat
read_data.read.output_shape = per_beat_output_bank
read_data.read.status_aggregation_generated_behavior = true
read_data.read.multi_beat_reassembly_generated_behavior = true
read_data.residue = []
```

Response-demux remains the generated mixed `RID && RLAST` contract and keeps
only same-ID ordering residue for this sample:

```text
response_demux.mode = bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.residue = [same_id_ordering]
```

## Validation

Direct guarded probes passed for the new public sample:

```text
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --verify-hdl ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
```

Focused regression coverage is in
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and support
accounting is in `t/248-regression-corpus-accounting.t`.

## Next Frontier

`.291` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.292`, a selector for the
next mixed dynamic/static frontier after generated mixed multi-beat output
banks. Multiple mixed dynamic/static transactions, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.

The `.289` scalar runtime sample and `.287` report-only sample remain
support-accounted and unchanged.
