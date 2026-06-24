# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.337`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.337` ships generated multi-beat
read-data output banks over generated one-dynamic plus three-concrete-static
mixed dynamic/static runtime-validation read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif
```

This sample is the multi-beat sibling of the `.335` runtime-validation
sample. It keeps the same `r0`, `r1`, `r2`, and `r3` transaction set,
generated mixed `RID && RLAST` response-demux, request-captured raw `ARLEN`,
expected-beat storage, read-beat counters, and runtime assertions, then
replaces scalar last-beat `RDATA`/`RRESP` outputs with per-beat output banks
and scalar worst-observed `RRESP` aggregates.

## Public Shape

The supported source shape requires:

- exactly one read transaction with `(id dynamic)`;
- exactly three read transactions with pairwise-distinct concrete static IDs;
- `response-demux.read` with `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`,
  `status-aggregation.policy worst-observed`, and `interleaving
  multi-beat-by-rid`;
- `burst-length` uses `source arlen`, width-8 `axi0_arlen`,
  `axlen-plus-one`, request capture, `max-beats 1..256`, and
  `validation runtime-assertion`; and
- every covered transaction supplies a data output prefix, status output
  prefix, scalar status aggregate output, valid-mask output, and length
  output.

Other mixed dynamic/static cardinalities remain fail-closed until selected by
a later exact owner.

## Generated Behavior

For the public four-transaction, 16-beat sample, FSMGen emits shared generated
inputs for `RDATA`, `RRESP`, and `ARLEN`, then emits per-transaction state:

```text
axi0_r0_arlen_q
axi0_r1_arlen_q
axi0_r2_arlen_q
axi0_r3_arlen_q
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r2_expected_beats_q
axi0_r3_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
axi0_r2_read_beat_count_q
axi0_r3_read_beat_count_q
```

Each transaction request initializes that transaction's output bank: data
lanes to zero, status lanes to zero, scalar aggregate status to zero, valid
mask to zero, and length output to zero. The same request captures raw
`ARLEN`, initializes expected beats to `ARLEN + 1`, and clears the
transaction's read-beat counter.

Lane capture uses raw accepted read beats. The dynamic transaction captures a
lane when `axi0_read_complete` is true, the dynamic transaction is busy, and
`axi0_rid` matches `axi0_r0_dynamic_id_q`. Static transactions capture lanes
when their static busy state is active and `axi0_rid` matches the reserved
concrete IDs `4'd3`, `4'd5`, or `4'd7`. Lane capture is indexed by the
pre-increment read-beat counter and is not gated by `RLAST`; the final
`RID && RLAST` beat remains the response-demux completion/release boundary.

The public sample emits:

- 64 generated `RDATA` lane outputs, 16 each for `r0`, `r1`, `r2`, and `r3`;
- 64 generated `RRESP` lane outputs, 16 each for `r0`, `r1`, `r2`, and `r3`;
- valid-mask outputs `axi0_r0_beat_valid`, `axi0_r1_beat_valid`,
  `axi0_r2_beat_valid`, and `axi0_r3_beat_valid`;
- length outputs `axi0_r0_read_beats`, `axi0_r1_read_beats`,
  `axi0_r2_read_beats`, and `axi0_r3_read_beats`;
- scalar worst-observed status outputs `axi0_r0_rresp`, `axi0_r1_rresp`,
  `axi0_r2_rresp`, and `axi0_r3_rresp`;
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
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
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

Response-demux reports the generated one-dynamic plus three-static read
burst-last contract and leaves only same-ID ordering residue:

```text
response_demux.mode =
  bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.residue = [same_id_ordering]
```

Read-data residue removes `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` for the supported sample.

## Deferred Boundaries

Two-dynamic-plus-static shapes, broader mixed dynamic/static cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, and full-manager behavior remain
later exact owners.

The `.335` scalar runtime-validation sample, `.333` report-only raw-`ARLEN`
sample, `.330` scalar read-data samples, `.326` burst-last response-demux
sample, `.314` two-static mixed multi-beat sample, `.291` one-static mixed
multi-beat sample, and `.268` multiple all-dynamic multi-beat sample remain
support-accounted and unchanged.

`.337` selects `.338`, the next exact-owner selector after the generated
three-static mixed dynamic/static read-data chain reached multi-beat output
banks.

## Validation

The `.337` slice added the public PPIF sample, support-accounting catalog
entry, focused generator/report/HDL assertions, regression-corpus accounting,
README, ROADMAP_V2, mdBook, task-tree, Memory, and Knowledge Map updates.

Validation evidence is recorded in the owning task-tree leaf.
