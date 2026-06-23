# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read-Data Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.330`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.330` ships generated bounded scalar
read-data capture over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif
```

Both samples cover dynamic read transaction `r0` plus concrete static read
transactions `r1`, `r2`, and `r3` with concrete read IDs `3`, `5`, and `7`.
The single-beat sample consumes generated `RID` completion pulses from
`response-scope single-beat`; the last-beat sample consumes generated
`RID && RLAST` completion pulses from `response-scope burst-last`.

## Public Shape

The single-beat sample adds scalar read-data bindings for all four covered
transactions:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))
    (transaction r3
      (data-output axi0_r3_rdata)
      (status-output axi0_r3_rresp))))
```

The last-beat sample uses `capture-scope last-beat`, `status-policy
last-beat`, `interleaving last-beat-by-rid`, and scalar last-beat output
names `axi0_r0_last_rdata`/`axi0_r0_last_rresp` through
`axi0_r3_last_rdata`/`axi0_r3_last_rresp`.

## Generated Behavior

The generator accepts this shape only when:

- `response-demux.read` is generated multiple mixed dynamic/static read demux;
- the demux completion source is
  `generated_multi_mixed_dynamic_static_read_demux` for scalar single-beat
  capture or `generated_multi_mixed_dynamic_static_read_demux_last_beat` for
  scalar last-beat capture;
- no `burst_length` metadata is present;
- the demux covers exactly one dynamic read transaction and exactly three
  concrete static read transactions; and
- `read-data.read.transactions` exactly covers `r0`, `r1`, `r2`, and `r3`
  once.

For each covered transaction the generated IAL1 includes the shared
`axi0_rdata`/`axi0_rresp` inputs, scalar data/status outputs, and one
capture rule guarded only by that transaction's generated response-demux
completion pulse. The new third static path emits, for example:

```text
(rule axi0_r3_read_data_capture axi0_r3_complete
  (axi0_r3_rdata axi0_rdata)
  (axi0_r3_rresp axi0_rresp))
```

The last-beat sample uses the same capture-rule name and guard, but captures
into `axi0_r3_last_rdata` and `axi0_r3_last_rresp`. It does not generate
`axi0_arlen`.

## Report Contract

The single-beat read-data report keeps:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
read_data.read.transactions = r0, r1, r2, r3
read_data.residue = rlast_completion, bursts, multi_beat_read_data_reassembly
```

The last-beat read-data report keeps:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.transactions = r0, r1, r2, r3
read_data.residue =
  multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation,
  arlen_or_beat_count_validation
```

Both reports list generated completion signals `axi0_r0_complete` through
`axi0_r3_complete`, generated read-data rules `axi0_r0_read_data_capture`
through `axi0_r3_read_data_capture`, and generated read-data inputs
`axi0_rdata`/`axi0_rresp`.

The response-demux report remains owned by the existing list-shaped modes:

- `bounded_multi_mixed_dynamic_static_read_rid_demux_contract` for
  single-beat completion; and
- `bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` for
  last-beat completion.

## Boundary

This slice widens only scalar no-`burst_length` read-data coverage from
one-dynamic plus one- or two-concrete-static generated mixed read demux to
one-dynamic plus one-, two-, or three-concrete-static generated mixed read
demux.

Three-static raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
validation, multi-beat output banks, two-dynamic-plus-static shapes, broader
mixed cardinalities, same-cycle request widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact-owner work.

The existing one-static and two-static scalar read-data shapes, two-static
report-only raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat
output-bank shapes remain the owners for their already selected behavior.

## Validation

Validation for `.330` covered the two new public samples plus adjacent
two-static and three-static preservation paths:

- syntax checks passed for `AxiManagerCapacityStatus.pm`,
  `RegressionCorpus.pm`, `t/1438`, and `t/248`;
- filtered focused `t/1438` passed for
  `mixed_dynamic_static_read_data_multi_static3`;
- filtered focused `t/1438` passed for
  `mixed_dynamic_static_read_data_multi_static3_last_beat`;
- preservation filters passed for the existing two-static scalar, last-beat,
  report-only raw-`ARLEN`, runtime-validation, and multi-beat read-data
  samples;
- `t/248-regression-corpus-accounting.t` passed `1..4478`;
- guarded direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes passed for both new public samples; and
- the strict check JSON reruns matched support-accounting entries
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data`
  and
  `intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data`.

An initial six-way guarded direct probe run killed the two concurrent strict
check workers at the host-memory cutoff; rerunning those strict checks one at
a time under the same guard passed.

## Rollback

Rollback is the `.330` implementation commit. Reverting it removes the two
public three-static mixed read-data PPIF samples, support-accounting entries,
scalar read-data admission widening, focused tests, docs, and fact card,
restoring `.330` as the active implementation frontier.
