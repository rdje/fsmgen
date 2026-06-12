# AXI IAL2 Manager Auto-ID Residue Alignment First Slice

This note records the implementation outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.32`.

## Shipped Boundary

After generated write `BID` response demux shipped, explicit
`response-demux` contracts drive auto-ID release from generated completion
pulses:

```text
axi0_write_complete + axi0_bid match -> pulse axi0_w0_complete
axi0_w0_complete -> axi0_w0_auto_id_release
```

The `.32` slice aligns the report with that behavior. When
`response_demux.generated_behavior` is true, FSMGen now removes
`response_demux` from `auto_id_lifecycle.residue`.

Current report shape for the checked-in response-demux sample:

```text
auto_id_lifecycle:
  generated_behavior: true
  residue:
    - same_id_ordering

id_response_rule_engine:
  residue:
    - same_id_ordering

response_demux:
  generated_behavior: true
  residue:
    - read_response_demux
    - same_id_ordering
    - read_data_interleaving
    - bursts
```

Samples without generated response-demux behavior keep their existing
`auto_id_lifecycle.residue` entry for `response_demux`, because their
completion release is not driven by generated demux pulses.

## Generated Artifact Boundary

This slice is report-contract cleanup only. It does not change generated
`.isf`, generated `.fsm`, or SystemVerilog HDL behavior.

## Runnable Sample

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

Focused generator and PPIF/CLI tests cover the aligned report shape.

## Residue

Same-ID ordering, read `RID` response demux, read-data interleaving/reassembly,
bursts, queued/blocking policy, profile aliases, full AXI manager behavior,
and VHDL backend/reroute behavior remain future exact-owner work.
