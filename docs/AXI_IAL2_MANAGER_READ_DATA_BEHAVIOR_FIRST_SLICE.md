# AXI IAL2 Manager Read Data Behavior First Slice

Status: shipped.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.47`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the generated behavior selected by
[docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md)
for the public contract shipped in
[docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md).

## Shipped Behavior

For an explicit bounded single-beat `read-data` contract with generated read
response-demux metadata, FSMGen now generates `RDATA`/`RRESP` capture through
the normal `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.

The checked-in sample is:

```bash
ppif/axi_manager_capacity_status_read_data.ppif
```

The generated IAL1 review artifact now includes width-bearing source inputs:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It also includes per-transaction capture outputs with inherited widths:

```text
(output axi0_r0_rdata (width 32))
(output axi0_r0_rresp (width 2))
(output axi0_r1_rdata (width 32))
(output axi0_r1_rresp (width 2))
```

Each read-data transaction gets one normal guarded capture rule. The guard is
the generated read response-demux completion pulse for that transaction:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
```

The capture actions are ordinary held assignments, not `(pulse ...)` actions.
That is intentional: completion signals remain one-cycle pulses, while
payload/status outputs keep their captured values until the next matching
completion pulse updates them.

## Report Contract

Schedule JSON now reports `read_data.generated_behavior: true` and publishes
machine-readable generated artifacts:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    data_signal: axi0_rdata
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_width: 2
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_rdata
      - axi0_r0_rresp
      - axi0_r1_rdata
      - axi0_r1_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

The `read_data.residue` list removes `generated_read_data_capture` and keeps:

```text
rlast_completion
bursts
multi_beat_read_data_reassembly
```

The broader `response_demux.residue` still includes read-data interleaving and
bursts, because this slice captures bounded single-beat payload/status values
but does not implement multi-beat reassembly, burst `RLAST` completion, or
per-ID read-data queues.

## HDL Reachability

The generated `.fsm` contains capture assignments such as:

```text
(-axi0_r0_read_data_capture <axi0_r0_complete
  (<- (axi0_r0_rdata> axi0_rdata))
  (<- (axi0_r0_rresp> axi0_rresp)))
```

SystemVerilog declares the generated payload/status ports and lowers the
capture to flopped output updates guarded by the generated completion:

```text
input  wire [31:0] axi0_rdata
input  wire [1:0]  axi0_rresp
output reg  [31:0] axi0_r0_rdata
output reg  [1:0]  axi0_r0_rresp
```

The public sample passes `--verify-hdl`.

## Explicit Deferrals

This slice does not implement:

- `RLAST`-driven completion;
- burst or multi-beat read-data assembly;
- different-ID read-data reassembly queues;
- concrete-ID same-ID issue-order queues;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.
