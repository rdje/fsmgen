# AXI IAL2 Manager Multiple Dynamic Multi-Beat Behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.268`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.268` ships generated bounded multiple
dynamic multi-beat read-data output-bank behavior over generated multiple
dynamic read burst-last response-demux and runtime beat-count/`RLAST`
validation.

The supported public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
```

The `multi_transaction_multi_beat` stem is intentionally explicit: existing
`dynamic_read_data_multi` samples cover multiple dynamic transactions with
scalar output data, while the older `dynamic_read_data_multi_beat` sample is
the single-active dynamic multi-beat output-bank shape.

## Source Shape

The supported source shape requires:

- two or more read transactions;
- every covered read transaction uses `(id dynamic)`;
- generated `response-demux.read` with `response-scope burst-last`, a
  one-bit `last-signal`, and `transaction-completion generated`;
- `read-data.read capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation.policy worst-observed`;
- `interleaving multi-beat-by-rid`;
- request-captured `ARLEN` burst-length metadata with `validation
  runtime-assertion`; and
- exactly one complete output-bank binding for every generated dynamic read
  demux transaction.

Each output-bank binding must provide a data output prefix, status output
prefix, scalar status aggregate output, valid-mask output, and length output.
Mixed dynamic/static transaction families remain fail-closed.

## Generated Behavior

For the public two-transaction, 16-beat sample, FSMGen emits shared generated
inputs for `RDATA`, `RRESP`, and `ARLEN`, then emits per-transaction state for
raw `ARLEN`, expected beats, and read-beat counters:

```text
axi0_r0_arlen_q
axi0_r1_arlen_q
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
```

Each transaction request initializes only that transaction's output bank:
data lanes to zero, status lanes to zero, scalar aggregate status to zero,
valid mask to zero, and length output to zero. The same request captures raw
`ARLEN`, initializes expected beats to `ARLEN + 1`, and clears the
transaction's read-beat counter.

Lane capture uses the raw accepted dynamic read beat whose `RID` matches the
transaction's captured dynamic ID while that transaction is busy. It does not
wait for final `RID && RLAST`; the final `RID && RLAST` beat remains the
generated response-demux completion and release boundary.

The public sample emits:

- 32 generated `RDATA` lane outputs, 16 for `r0` and 16 for `r1`;
- 32 generated `RRESP` lane outputs, 16 for `r0` and 16 for `r1`;
- valid-mask outputs `axi0_r0_beat_valid` and `axi0_r1_beat_valid`;
- length outputs `axi0_r0_read_beats` and `axi0_r1_read_beats`;
- scalar worst-observed status aggregate outputs `axi0_r0_rresp` and
  `axi0_r1_rresp`;
- per-lane capture rules for each bounded beat of each transaction;
- per-transaction output-bank init, burst-length capture, beat-count init,
  beat-count increment, and scalar status aggregate rules; and
- four runtime assertions per transaction:
  `arlen_within_max`, `read_beat_before_expected_count`,
  `rlast_on_expected_beat`, and `expected_final_beat_has_rlast`.

Scalar status aggregation uses worst-observed `RRESP`: each aggregate starts
at zero at request time and updates when a matched beat carries a numerically
larger two-bit response status.

## Report Contract

Schedule/check/semantic JSON reports the read-data shape as:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_last_beat_completion_pulse
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

Response-demux reports the same generated multiple dynamic read burst-last
contract as `.255` and the same-ID ordering residue remains:

```text
response_demux.mode = bounded_multi_dynamic_read_rid_rlast_demux_contract
response_demux.residue = [same_id_ordering]
```

Read-data residue removes `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` for the supported sample.

## Validation

The `.268` slice added the public PPIF sample, support-accounting catalog
entry, parser/CLI coverage, focused generator and dynamic behavior tests, and
support-accounting expectations. Syntax checks passed for the generator,
support catalog, and focused test files. Guarded direct probes passed for
schedule JSON, strict check JSON, semantic JSON, and SystemVerilog
`--verify-hdl`.

Guarded focused validation passed for:

```text
prove -Iperl -lv t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
prove -Iperl -lv t/248-regression-corpus-accounting.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
```

The broad guarded `t/1436-ial2-ppif-parser-cli.t` run was stopped by the RAM
guard while an unrelated existing mixed auto-ID sample exceeded the configured
per-process RSS limit. The `.268` public sample itself passed direct parser,
schedule, check, semantic, and HDL probes.

## Deferred Boundaries

Mixed dynamic/static demux, same-cycle request widening beyond the current
onehot0 policy, same-cycle release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain later exact owners.

The shipped `.243` single-active dynamic multi-beat sample, `.259` scalar
multiple dynamic read-data samples, `.263` report-only raw-`ARLEN` sample, and
`.264` runtime beat-count/`RLAST` sample remain supported.
