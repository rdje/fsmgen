# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Runtime-Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.312`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.312` ships generated runtime
beat-count/`RLAST` validation over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif
```

This sample is the runtime sibling of the `.310` report-only sample. It keeps
the same one dynamic plus two concrete static read transaction set, generated
multiple mixed `RID && RLAST` response-demux, scalar last-beat `RDATA`/`RRESP`
capture, and request-captured raw `ARLEN` metadata, changing only
`burst-length.validation` to `runtime-assertion`.

## Public Shape

The supported runtime source shape requires:

- exactly one read transaction with `(id dynamic)`;
- exactly two read transactions with pairwise-distinct concrete static IDs;
- `response-demux.read` with `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read.transactions` covers the ordered `r0`, `r1`, and `r2`
  transaction set exactly once; and
- `burst-length` uses `source arlen`, width-8 `axi0_arlen`,
  `axlen-plus-one`, request capture, `max-beats 1..256`, and
  `validation runtime-assertion`.

## Generated Behavior

For the public sample FSMGen emits the shared generated `axi0_arlen` input
plus per-transaction state:

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

Each request captures raw `ARLEN`, initializes expected beats to `ARLEN + 1`,
and clears that transaction's beat counter. Each raw accepted read beat that
matches the active transaction increments that transaction's beat counter.
The dynamic transaction matches the captured dynamic `RID`; each static
transaction matches its reserved concrete `RID`. The matched-beat counter path
is not gated by `RLAST`; the runtime assertions check whether `RLAST` appears
exactly on the expected final beat.

For each covered transaction, FSMGen emits four runtime assertions:

```text
axi0_<tx>_arlen_within_max
axi0_<tx>_read_beat_before_expected_count
axi0_<tx>_rlast_on_expected_beat
axi0_<tx>_expected_final_beat_has_rlast
```

The public three-transaction sample therefore reports twelve generated
beat-count assertions.

Scalar `RDATA`/`RRESP` capture remains guarded only by each transaction's
generated multiple mixed `RID && RLAST` completion pulse.

## Report Contract

The schedule report keeps the scalar last-beat mode:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_count_validation_generated_behavior = true
read_data.read.expected_beat_count_encoding = arlen_plus_one
read_data.read.beat_count_match_source = response_demux_matched_read_beat
```

Runtime generation reports the generated expected-beat storage,
read-beat-count storage, beat-count rules, and beat-count assertions. It
removes `generated_beat_count_validation` from read-data residue.
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` remain residue because this slice still produces scalar
last-beat outputs rather than multi-beat output banks.

## Deferred Boundaries

Multiple mixed dynamic/static multi-beat output banks, broader mixed
dynamic/static cardinalities, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain later exact owners.

The `.310` report-only sample remains support-accounted and continues to emit
raw `ARLEN` capture without expected-beat storage, beat counters, beat-count
rules, or runtime assertions.

`.312` selects `.313`, readiness audit for generated multiple mixed
dynamic/static multi-beat output banks over this runtime-validation boundary.

## Validation

The implementation is covered by the support-accounted public sample, focused
dynamic transaction-ID test coverage, support-accounting coverage, syntax
checks, schedule/report/HDL probes, mdBook, Knowledge Map, memory, diff, and
doctrine gates recorded in the owning task-tree leaf.
