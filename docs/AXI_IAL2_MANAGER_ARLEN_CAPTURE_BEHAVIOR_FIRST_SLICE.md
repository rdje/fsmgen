# AXI IAL2 Manager ARLEN Capture Behavior First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.66`

This slice ships generated raw-ARLEN capture for explicit AXI manager
last-beat `read-data` contracts that include `burst-length` metadata with
`source arlen`.

## Public Contract

The public `.ppif` syntax was selected and parsed in earlier slices. The
behavior-bearing shape is still:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation report-only))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The captured storage value is raw `ARLEN`. The report keeps
`burst_length_encoding: axlen_plus_one` so later owners know the expected beat
count is `raw_ARLEN + 1`. This slice does not compute that derived count.

## Generated IAL1

The generator now adds the selected ARLEN signal as a generated width-8 input,
one raw-ARLEN storage variable per covered read transaction, and one guarded
capture rule per transaction:

```text
(input axi0_arlen (width 8))

(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))

(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

The guard is the transaction request event, not the RLAST completion pulse.
The existing last-beat `RDATA`/`RRESP` capture remains guarded by generated
read response-demux completion pulses.

## Lowered Artifacts

The generated `.fsm` carries the same raw-ARLEN assignments:

```text
(-axi0_r0_burst_length_capture <axi0_r0_request
  (<- (axi0_r0_arlen_q axi0_arlen))
)
```

SystemVerilog exposes `axi0_arlen` as an input, declares
`axi0_r0_arlen_q`/`axi0_r1_arlen_q` as 8-bit registers, drives
`axi0_r0_burst_length_capture_en = axi0_r0_request`, and assigns
`axi0_r0_arlen_q_next = axi0_arlen` when the capture rule fires.

## Schedule Report

For `ppif/axi_manager_capacity_status_read_data_burst_length.ppif`, schedule
JSON now reports:

```text
read_data:
  generated_behavior: true
  read:
    burst_length_source: arlen_signal
    burst_length_signal: axi0_arlen
    burst_length_signal_width: 8
    burst_length_encoding: axlen_plus_one
    burst_length_capture: transaction_request
    max_beats: 16
    burst_length_generated_behavior: true
    burst_length_validation: report_only
    generated_burst_length_inputs:
      - axi0_arlen
    generated_burst_length_storage:
      - axi0_r0_arlen_q
      - axi0_r1_arlen_q
    generated_burst_length_rules:
      - axi0_r0_burst_length_capture
      - axi0_r1_burst_length_capture
```

The general generated read-data artifact lists also include `axi0_arlen` in
`generated_inputs` and the two burst-length capture rules in
`generated_rules`.

The read-data residue removes `generated_burst_length_capture` and keeps the
remaining future owners explicit:

```text
generated_beat_count_validation
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

## Deferred Work

This slice intentionally leaves these behaviors out of scope:

- expected-beat arithmetic from raw `ARLEN + 1`;
- beat-count/RLAST validation and missing/extra-beat diagnostics;
- beat-index state;
- payload storage and multi-beat reassembly;
- per-beat outputs;
- `RRESP` aggregation;
- per-ID response queues;
- direct backend lowering;
- VHDL backend/reroute behavior.

The next selected task-tree leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.67`, a readiness audit for beat-count and
RLAST validation after generated raw-ARLEN capture.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```
