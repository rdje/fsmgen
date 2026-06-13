# AXI IAL2 Manager Last-Beat Read-Data Behavior First Slice

Status: shipped.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.60`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the generated behavior selected by
[docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md)
for the public contract shipped in
[docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md).

## Shipped Behavior

For an explicit last-beat `read-data` contract paired with generated
burst-last read response-demux metadata, FSMGen now generates last-beat
`RDATA`/`RRESP` capture through the normal
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_data_last_beat.ppif
```

The generated IAL1 review artifact includes width-bearing source inputs:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It also includes per-transaction last-beat capture outputs with inherited
widths:

```text
(output axi0_r0_last_rdata (width 32))
(output axi0_r0_last_rresp (width 2))
(output axi0_r1_last_rdata (width 32))
(output axi0_r1_last_rresp (width 2))
```

Each read-data transaction gets one normal guarded capture rule. The guard is
that transaction's generated burst-last response-demux completion pulse:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

The capture actions are ordinary held assignments, not `(pulse ...)` actions.
The generated completion pulse remains the one-cycle validity strobe, while
last-beat data/status outputs retain the captured values until the next
matching last-beat completion.

## Report Contract

Schedule JSON now reports generated behavior for the last-beat contract:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    status_aggregation: none
    burst_length_source: rlast_only
    beat_storage: none
    valid_output: none
    length_output: none
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_last_rdata
      - axi0_r0_last_rresp
      - axi0_r1_last_rdata
      - axi0_r1_last_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

The `read_data.residue` list removes
`generated_last_beat_read_data_capture` and keeps:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
arlen_or_beat_count_validation
```

The broader `response_demux.residue` still includes `read_data_interleaving`
and `bursts`, because this slice captures only the matched last beat. It does
not implement multi-beat reassembly, per-beat output coverage, all-beat
`RRESP` aggregation, `ARLEN` validation, or per-ID data queues.

## HDL Reachability

The generated `.fsm` contains capture assignments such as:

```text
(-axi0_r0_read_data_capture <axi0_r0_complete
  (<- (axi0_r0_last_rdata> axi0_rdata))
  (<- (axi0_r0_last_rresp> axi0_rresp)))
```

SystemVerilog declares the generated payload/status inputs and last-beat
outputs, then lowers the capture to flopped output updates guarded by the
generated last-beat completion:

```text
input  wire [31:0] axi0_rdata
input  wire [1:0]  axi0_rresp
output reg  [31:0] axi0_r0_last_rdata
output reg  [1:0]  axi0_r0_last_rresp
```

The public sample passes `--verify-hdl`.

## Explicit Deferrals

This slice does not implement:

- full multi-beat read-data reassembly;
- per-beat outputs or packed burst outputs;
- `RRESP` aggregation across all beats;
- `ARLEN`, expected beat-count, fixed-depth, missing-beat, or extra-beat
  validation;
- different-ID multi-beat reassembly queues;
- same-ID concrete-ID issue-order queues;
- queued or blocking submission policy;
- full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.61` owns the next AXI manager
feature-completeness selector after generated last-beat capture. That selector
must choose the next exact owner from the remaining read-data reassembly,
per-beat output, `RRESP` aggregation, `ARLEN`/beat-count validation, per-ID
queue, full-manager, direct backend, or VHDL-deferred residue.
