# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.314`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.314` ships generated multiple mixed
dynamic/static multi-beat read-data output banks over generated multiple mixed
dynamic/static read burst-last response-demux and runtime beat-count/`RLAST`
validation.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif
```

This sample is the multi-beat sibling of the `.312` runtime-validation sample.
It keeps the same one dynamic plus two concrete static read transaction set,
generated multiple mixed `RID && RLAST` response-demux, request-captured raw
`ARLEN`, expected-beat storage, read-beat counters, and runtime assertions,
then replaces scalar last-beat `RDATA`/`RRESP` outputs with per-beat output
banks and scalar worst-observed `RRESP` aggregates.

## Public Shape

The supported source shape requires:

- exactly one read transaction with `(id dynamic)`;
- exactly two read transactions with pairwise-distinct concrete static IDs;
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

Other mixed dynamic/static cardinalities remain fail-closed.

## Generated Behavior

For the public three-transaction, 16-beat sample, FSMGen emits shared
generated inputs for `RDATA`, `RRESP`, and `ARLEN`, then emits
per-transaction state:

```text
axi0_r0_arlen_q
axi0_r1_arlen_q
axi0_r2_arlen_q
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r2_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
axi0_r2_read_beat_count_q
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
concrete IDs `4'd3` or `4'd5`. Lane capture is indexed by the pre-increment
read-beat counter and is not gated by `RLAST`; the final `RID && RLAST` beat
remains the response-demux completion/release boundary.

The public sample emits:

- 48 generated `RDATA` lane outputs, 16 each for `r0`, `r1`, and `r2`;
- 48 generated `RRESP` lane outputs, 16 each for `r0`, `r1`, and `r2`;
- valid-mask outputs `axi0_r0_beat_valid`, `axi0_r1_beat_valid`, and
  `axi0_r2_beat_valid`;
- length outputs `axi0_r0_read_beats`, `axi0_r1_read_beats`, and
  `axi0_r2_read_beats`;
- scalar worst-observed status outputs `axi0_r0_rresp`, `axi0_r1_rresp`, and
  `axi0_r2_rresp`;
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

Response-demux reports the same generated multiple mixed read burst-last
contract as `.303` and leaves only same-ID ordering residue:

```text
response_demux.mode =
  bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.residue = [same_id_ordering]
```

Read-data residue removes `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` for the supported sample.

## Validation

The `.314` slice added the public PPIF sample, support-accounting catalog
entry, focused generator/report/HDL assertions, regression-corpus accounting,
README, ROADMAP_V2, mdBook, task-tree, Memory, and Knowledge Map updates.

Syntax checks passed for the generator, support catalog, and focused tests.
Focused validation for the new public sample passed with 98 assertions under:

```text
env FSMGEN_DYNAMIC_CASE_FILTER=multi_static_burst_last_read_data_multi_beat FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 perl -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Support-accounting, direct probes, preservation checks, mdBook, Knowledge Map,
memory, diff, and doctrine validation are recorded in the owning task-tree
leaf.

## Deferred Boundaries

Broader mixed dynamic/static cardinalities, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain later exact owners.

The `.312` scalar runtime-validation sample, `.310` report-only sample,
`.307` scalar read-data samples, `.291` one-dynamic plus one-static
multi-beat sample, and `.268` multiple all-dynamic multi-beat sample remain
support-accounted and unchanged.

`.314` selects `.315`, the next exact-owner selector after the generated
multiple mixed dynamic/static read-data chain reached multi-beat output banks.
