# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Multi-Beat Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.357`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.357` ships generated multi-beat
output banks over generated two-dynamic-plus-one-static mixed dynamic/static
runtime-validation read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif
```

It is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat
```

with coverage:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli
```

and focused behavior label:

```text
mixed_dynamic_static_read_data_multi_dynamic_multi_beat
```

## Public Shape

The supported multi-beat source shape requires:

- exactly two read transactions with `(id dynamic)`, `r0` and `r1`;
- exactly one read transaction with a concrete static ID, `r2` reserved to
  `RID` value `3`;
- `response-demux.read` with `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, worst-observed status
  aggregation, and `interleaving multi-beat-by-rid`;
- `burst-length` uses `source arlen`, width-8 `axi0_arlen`,
  `axlen-plus-one`, request capture, `max-beats 1..256`, and
  `validation runtime-assertion`; and
- each covered transaction binds a data output prefix, status output prefix,
  scalar status aggregate output, valid-mask output, and read-length output.

## Generated Behavior

The generated surface preserves the `.355` runtime beat-count/`RLAST`
validation, the `.353` raw-`ARLEN` capture, and the `.347` final
`RID && RLAST` completion pulses. It replaces scalar last-beat read-data
outputs with per-transaction output banks.

For each covered transaction, FSMGen emits:

```text
axi0_<tx>_beat_rdata_0 .. axi0_<tx>_beat_rdata_15
axi0_<tx>_beat_rresp_0 .. axi0_<tx>_beat_rresp_15
axi0_<tx>_beat_valid
axi0_<tx>_read_beats
axi0_<tx>_rresp
```

Request-time initialization clears the output bank, valid mask, length, and
scalar aggregate status for the requested transaction. Each raw accepted read
beat that matches the active transaction captures `RDATA` and per-beat
`RRESP` into the lane selected by that transaction's current read-beat
counter, updates the valid mask and length, and folds the scalar `RRESP`
aggregate with the worst observed status. The dynamic transactions match
active busy state plus the captured dynamic `RID`; the static transaction
matches `axi0_r2_static_busy_q` and `axi0_rid == 4'd3`.

The lane capture and beat-count increment path is intentionally not gated by
`RLAST`; final completion and ID release remain driven by the generated
mixed `RID && RLAST` completion pulse. Runtime assertions from `.355` still
check whether `RLAST` appears exactly on the expected final beat.

## Report Contract

The schedule report identifies this as a bounded multi-beat read-data
contract:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.capture_scope = multi_beat
read_data.read.status_policy = per_beat
read_data.read.status_aggregation = worst_observed
read_data.read.interleaving = multi_beat_by_rid
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_count_match_source = response_demux_matched_read_beat
read_data.read.status_aggregation_generated_behavior = true
read_data.read.multi_beat_reassembly_generated_behavior = true
```

For the public sample, `read_data.residue` is empty. `response_demux.residue`
keeps only `same_id_ordering`; read-data interleaving, burst tracking, and
multi-beat output-bank behavior are no longer response-demux residue for this
exact boundary.

## Deferred Boundaries

Single-beat read-data over the `.344` demux, broader mixed dynamic/static
cardinalities, same-cycle request widening, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, VHDL, profile aliases, queued/blocking policy, and full-manager
behavior remain later exact owners.

The `.353` report-only sibling and the `.355` scalar runtime-validation
sibling remain support-accounted and continue to emit scalar last-beat
read-data behavior rather than multi-beat output banks.

`.357` selects `.358`, the next IAL2 feature-completeness selector after the
two-dynamic-plus-one-static mixed dynamic/static read-data chain reached
multi-beat output banks.

## Validation

Validation for `.357` included syntax checks for touched Perl modules/tests,
guarded direct schedule probes for the new multi-beat sample, guarded
support-accounting validation, and a guarded focused t/1438 filter for the
new behavior. Broader doctrine, mdBook, Knowledge Map, memory, and diff gates
are recorded in the owning task-tree leaf.
