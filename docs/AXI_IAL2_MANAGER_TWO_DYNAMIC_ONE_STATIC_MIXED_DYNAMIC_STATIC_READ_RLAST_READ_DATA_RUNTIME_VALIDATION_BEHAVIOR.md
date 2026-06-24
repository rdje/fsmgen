# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Runtime-Validation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.355`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.355` ships generated runtime
beat-count/`RLAST` validation over generated two-dynamic-plus-one-static
mixed dynamic/static raw-`ARLEN` scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif
```

It is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion
```

with coverage:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli
```

and focused behavior label:

```text
mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion
```

## Public Shape

The supported runtime source shape requires:

- exactly two read transactions with `(id dynamic)`, `r0` and `r1`;
- exactly one read transaction with a concrete static ID, `r2` reserved to
  `RID` value `3`;
- `response-demux.read` with `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read.transactions` covers `r0`, `r1`, and `r2` exactly once; and
- `burst-length` uses `source arlen`, width-8 `axi0_arlen`,
  `axlen-plus-one`, request capture, `max-beats 1..256`, and
  `validation runtime-assertion`.

## Generated Behavior

The generated surface preserves the `.353` report-only raw-`ARLEN` capture,
the `.350` scalar last-beat payload/status capture, and the `.347`
two-dynamic-plus-one-static final `RID && RLAST` completion pulses. It adds
per-transaction runtime validation state:

```text
axi0_r0_expected_beats_q
axi0_r1_expected_beats_q
axi0_r2_expected_beats_q
axi0_r0_read_beat_count_q
axi0_r1_read_beat_count_q
axi0_r2_read_beat_count_q
```

Each request captures raw `ARLEN`, initializes expected beats to `ARLEN + 1`,
and clears that transaction's read-beat counter. Each raw accepted read beat
that matches the active transaction increments that transaction's counter.
The dynamic transactions match active busy state plus the captured dynamic
`RID`; the static transaction matches `axi0_r2_static_busy_q` and
`axi0_rid == 4'd3`.

The matched-beat increment path is intentionally not gated by `RLAST`.
Runtime assertions check whether `RLAST` appears exactly on the expected final
beat.

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
generated mixed `RID && RLAST` completion pulse.

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
removes `generated_beat_count_validation` from read-data residue while keeping
multi-beat read-data reassembly, per-beat outputs, and `RRESP` aggregation as
residue because this slice still emits scalar last-beat outputs.

## Deferred Boundaries

Two-dynamic-plus-one-static mixed dynamic/static multi-beat output banks,
single-beat read-data over the `.344` demux, broader mixed dynamic/static
cardinalities, same-cycle request widening, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, VHDL, profile aliases, queued/blocking policy, and full-manager
behavior remain later exact owners.

The `.353` report-only sibling remains support-accounted and continues to
emit raw `ARLEN` capture without expected-beat storage, read-beat counters,
beat-count rules, or runtime assertions.

`.355` selects `.356`, readiness audit for generated two-dynamic-plus-one-static
mixed dynamic/static multi-beat output banks over this runtime-validation
boundary.

## Validation

Validation for `.355` included syntax checks for touched Perl modules/tests,
a guarded direct schedule JSON probe for the new runtime sample, guarded
semantic JSON attempts that stopped at the documented host-memory cutoff,
guarded `.353` report-only preservation schedule JSON, guarded
support-accounting validation, and a guarded focused t/1438 runtime filter.
The focused t/1438 filter passed parser/report/ISF/FSM assertions before the
host-memory guard stopped the isolated HDL inspection step at the documented
93% cutoff. Broader doctrine, mdBook, Knowledge Map, memory, and diff gates
are recorded in the owning task-tree leaf.
