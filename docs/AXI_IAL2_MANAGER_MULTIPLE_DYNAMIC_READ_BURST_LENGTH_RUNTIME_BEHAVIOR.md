# AXI IAL2 manager multiple dynamic read burst-length runtime behavior

Date: 2026-06-23
Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.264`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.264` ships generated runtime
beat-count/`RLAST` validation over generated multiple dynamic read burst-last
response-demux and scalar last-beat read-data.

The supported public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
```

This sample is the runtime sibling of the `.263` report-only sample. It keeps
the same all-dynamic transaction set, generated `RID && RLAST` response-demux,
scalar last-beat `RDATA`/`RRESP` capture, and request-captured raw `ARLEN`
metadata, changing only `burst-length.validation` to `runtime-assertion`.

## Source Shape

The supported runtime source shape requires:

- two or more read transactions;
- every covered read transaction uses `(id dynamic)`;
- `response-demux.read` uses `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read.transactions` covers every generated dynamic read demux
  transaction exactly once; and
- `burst-length.validation` is `runtime-assertion`.

## Generated Behavior

For the public two-transaction sample, FSMGen emits the shared generated
`axi0_arlen` input plus per-transaction state:

```text
axi0_r0_arlen_q
axi0_r1_arlen_q
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
```

Each request captures raw `ARLEN`, initializes expected beats to `ARLEN + 1`,
and clears that transaction's beat counter. Each raw accepted read beat whose
`RID` matches the active selected dynamic ID increments that transaction's
beat counter. The matched-beat counter path is not gated by `RLAST`; the
runtime assertions check whether `RLAST` appears exactly on the expected
final beat.

For each covered transaction, FSMGen emits four runtime assertions:

```text
axi0_<tx>_arlen_within_max
axi0_<tx>_read_beat_before_expected_count
axi0_<tx>_rlast_on_expected_beat
axi0_<tx>_expected_final_beat_has_rlast
```

The public two-transaction sample therefore reports eight generated
beat-count assertions.

## Report Contract

The schedule report keeps the scalar last-beat mode:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_count_validation_generated_behavior = true
read_data.read.expected_beat_count_encoding = arlen_plus_one
read_data.read.beat_count_match_source = response_demux_matched_read_beat
```

Runtime generation removes `generated_beat_count_validation` from read-data
residue. `multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` remain residue because this slice still produces scalar
last-beat outputs rather than multi-beat output banks.

## Deferred Boundaries

Multiple dynamic multi-beat output banks, mixed dynamic/static demux,
same-cycle request widening beyond the existing onehot0 policy,
release-and-recapture, dynamic same-ID queues and scoreboards, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.

The `.263` report-only sample remains support-accounted and continues to emit
raw `ARLEN` capture without expected-beat storage, beat counters, beat-count
rules, or runtime assertions.
