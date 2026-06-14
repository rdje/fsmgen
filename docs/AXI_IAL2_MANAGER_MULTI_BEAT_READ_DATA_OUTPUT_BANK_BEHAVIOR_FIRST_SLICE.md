# AXI IAL2 Manager Multi-Beat Read-Data Output-Bank Behavior First Slice

Status: shipped.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.74`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the generated behavior selected by
[docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md)
for the public contract shipped in
[docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md).

## Shipped Behavior

For the support-accounted sample:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

FSMGen now generates multi-beat read-data output-bank behavior through the
normal `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` path.

The generated IAL1 review artifact includes width-bearing payload inputs:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It also includes per-transaction data/status lane outputs, valid-mask
outputs, and length outputs:

```text
(output axi0_r0_beat_rdata_0 (width 32))
(output axi0_r0_beat_rresp_0 (width 2))
(output axi0_r0_beat_valid (width 16))
(output axi0_r0_read_beats (width 5))
```

Each transaction gets a request-time output-bank initialization rule. The rule
clears all generated data/status lanes, the valid mask, and the length output
for that transaction:

```text
(rule axi0_r0_read_data_output_init axi0_r0_request
  (axi0_r0_beat_rdata_0 32'd0)
  (axi0_r0_beat_rresp_0 2'd0)
  ...
  (axi0_r0_beat_valid 16'b0)
  (axi0_r0_read_beats 5'd0))
```

Each transaction also gets one lane capture rule per supported beat. Lane `0`
captures the current `RDATA`/`RRESP`, sets the valid mask to the first prefix
mask, and sets the length output to one:

```text
(rule axi0_r0_read_beat_0_capture
  (& (& axi0_read_complete (& axi0_r0_auto_id_busy_q (== axi0_rid axi0_r0_auto_id_q)))
     (! axi0_r0_request)
     (== axi0_r0_read_beat_count_q 5'd0))
  (axi0_r0_beat_rdata_0 axi0_rdata)
  (axi0_r0_beat_rresp_0 axi0_rresp)
  (axi0_r0_beat_valid 16'b0000000000000001)
  (axi0_r0_read_beats 5'd1))
```

Lane `N` uses the same matched-read-beat and `!request_event` boundary, plus
`beat_count_storage == N`. The valid mask is a constant prefix mask and the
length output is `N + 1`. This keeps the first generated behavior slice within
scalar output ports and mutually exclusive guarded assignments; it does not
introduce array ports, packed burst vectors, dynamic indexed assignments, or
hidden per-ID queues.

## Report Contract

Schedule JSON now reports generated multi-beat output-bank behavior:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    beat_match_source: response_demux_matched_read_beat
    output_shape: per_beat_output_bank
    multi_beat_reassembly_generated_behavior: true
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
      - axi0_arlen
    generated_multi_beat_output_init_rules:
      - axi0_r0_read_data_output_init
      - axi0_r1_read_data_output_init
    generated_multi_beat_capture_rules:
      - axi0_r0_read_beat_0_capture
      - ...
      - axi0_r1_read_beat_15_capture
```

`generated_outputs` lists every data lane, every status lane, each
valid-mask output, and each length output. Dedicated report fields also list
the generated data outputs, status outputs, valid-mask outputs, length
outputs, output-init rules, and lane capture rules.

The `read_data.residue` list now keeps only:

```text
rresp_aggregation
```

Scalar `RRESP` aggregation remains out of scope because this slice exposes
per-beat status lanes and does not select a scalar aggregate status policy.

## HDL Reachability

The generated `.fsm` contains the output-bank initialization and lane capture
assignments. SystemVerilog exposes the generated payload inputs and per-beat
outputs:

```text
input  wire [31:0] axi0_rdata
input  wire [1:0]  axi0_rresp
output reg  [31:0] axi0_r0_beat_rdata_0
output reg  [1:0]  axi0_r0_beat_rresp_0
output reg  [15:0] axi0_r0_beat_valid
output reg  [4:0]  axi0_r0_read_beats
```

The public multi-beat sample passes `--verify-hdl`.

## Compatibility

Existing single-beat read-data capture, last-beat read-data capture,
report-only burst-length metadata, raw-ARLEN capture, and
beat-count/`RLAST` runtime-validation behavior remain compatible. This slice
only enables payload/output-bank behavior for explicit
`capture-scope multi-beat` contracts with runtime-assertion burst-length
metadata.

## Validation Evidence

Focused `.74` validation includes:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-74-multi-beat.sv ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

Temporary HDL probe artifacts were removed after verification.

## Explicit Deferrals

This slice does not implement:

- scalar `RRESP` aggregation across all beats;
- packed burst-vector outputs;
- different-ID per-ID read-data queues;
- authored concrete-ID same-ID issue-order queues;
- queued or blocking submission policy;
- profile aliases or full-manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.75` owns the next AXI manager
feature-completeness selector after generated multi-beat read-data
output-bank behavior. That selector must choose the next exact owner from the
remaining scalar `RRESP` aggregation, per-ID queue, ordering, queued-policy,
profile/full-manager, direct-backend, or VHDL-deferred residue.
