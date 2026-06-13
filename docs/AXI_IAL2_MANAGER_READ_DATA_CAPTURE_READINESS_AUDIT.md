# AXI IAL2 Manager Read Data Capture Readiness Audit

Status: readiness audit complete; generated behavior remains unchanged in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.46`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This audit follows the parser/report metadata boundary shipped in
[docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md).

## Conclusion

Generated single-beat AXI read-data payload/status capture can be implemented
directly in the next slice. No new IAL1, IAL0, or SystemVerilog prerequisite is
required.

The selected next owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.47
```

That implementation leaf must remain bounded to the explicit public
`read-data` contract shipped by `.45`: single-beat `RDATA`/`RRESP` capture
only, with the generated read `RID` response-demux completion pulse as the
per-transaction validity strobe. `RLAST`, bursts, multi-beat read-data
reassembly, per-ID queues, full-manager behavior, direct backend lowering, and
VHDL remain residue.

## Evidence Read

- `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/book/src/13g-rules.md`
- `docs/ISF_SPEC.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl/FSM/Adapter/IAL2/PPIF.pm`
- `ppif/axi_manager_capacity_status_read_data.ppif`
- `t/1437-axi-ial2-manager-capacity-status-generator.t`
- `t/1436-ial2-ppif-parser-cli.t`

The baseline command:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif
```

confirms the `.45` state: `read_data.generated_behavior` is false,
`axi0_rdata` and `axi0_rresp` are structural generated-input candidates,
`axi0_r0_rdata`/`axi0_r0_rresp` and
`axi0_r1_rdata`/`axi0_r1_rresp` are structural generated-output candidates,
and `read_data.residue` still includes `generated_read_data_capture`.
The same report confirms that generated read response-demux behavior is already
present: `axi0_r0_complete` and `axi0_r1_complete` are generated completion
pulse outputs and remain the read capacity/auto-ID release events.

## Substrate That Already Fits

The shipped `.45` structural contract already contains the facts required for
bounded generated capture:

- the source payload signal, `axi0_rdata`, with width 32 in the checked-in
  sample;
- the source status signal, `axi0_rresp`, with width 2;
- one generated completion pulse per read transaction from the shipped read
  `RID` response demux;
- one transaction-bound data output and one status output per covered read
  transaction;
- exact coverage against generated read response-demux auto transactions.

The existing IAL1 substrate can carry the generated shape:

- IAL1 actor interfaces support width-bearing inputs and outputs such as
  `(input name (width N))` and `(output name (width N))`;
- IAL1 rule actions support ordinary guarded assignments through
  `(set target expr)` or `(target expr)`;
- ordinary rule assignments are flopped and therefore appropriate for held
  captured data/status values;
- IAL1 `(pulse TARGET)` remains reserved for one-cycle completion/event
  pulses, which is not the correct representation for payload/status outputs.

The existing AXI manager generator already emits width-bearing generated
outputs through `_width_output_line`, emits ID-width inputs through
`_input_line`, and emits ordinary multi-assignment rules through the same rule
shape used by capacity/status and auto-ID lifecycle rules. The next behavior
slice therefore needs generator wiring, not a new lowerer feature.

## Selected `.47` Behavior Boundary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.47` should implement:

- generated IAL1 inputs for the selected read-data source signals, for example
  `axi0_rdata (width 32)` and `axi0_rresp (width 2)`;
- generated IAL1 outputs for each transaction's capture targets, for example
  `axi0_r0_rdata (width 32)`, `axi0_r0_rresp (width 2)`,
  `axi0_r1_rdata (width 32)`, and `axi0_r1_rresp (width 2)`;
- one capture rule per read-data transaction, guarded by that transaction's
  generated read response-demux completion pulse;
- normal data/status assignments, not `(pulse ...)`, so the captured values
  remain held until the next matching completion pulse updates them;
- schedule/report JSON with `read_data.generated_behavior: true` plus generated
  input, output, and rule artifact lists;
- residue movement that removes `generated_read_data_capture` from
  `read_data.residue` and keeps `rlast_completion`, `bursts`, and
  `multi_beat_read_data_reassembly` residue visible.

The expected generated IAL1 rule shape is:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
```

The matching `.fsm` and SystemVerilog behavior should come from the existing
IAL1/IAL0 lowering path. The behavior owner must not introduce direct
IAL2-to-HDL generation.

## Report Expectations

After `.47`, the read-data report should remain under schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

Expected generated report additions:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    data_signal: axi0_rdata
    data_signal_direction: generated_input
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_direction: generated_input
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
  residue:
    - rlast_completion
    - bursts
    - multi_beat_read_data_reassembly
```

The exact shape may include richer per-transaction artifact objects if the
implementation keeps the already-shipped transaction binding entries as the
canonical home for per-transaction width and completion metadata. It must
remain machine-readable and structural; no raw assignment-line strings should
be the only contract for generated capture behavior.

## Diagnostics And Validation Scope

The next implementation leaf should keep the `.45` static diagnostics and add
focused generated-behavior coverage for:

- generated `RDATA`/`RRESP` input declarations with inherited widths;
- generated per-transaction data/status output declarations with inherited
  widths;
- generated capture rule names that are collision-free;
- `.isf`, `.fsm`, and SystemVerilog reachability for the checked-in read-data
  sample;
- check JSON and normalized semantic JSON support-accounting for the same
  public `.ppif` sample;
- `--verify-hdl` for `ppif/axi_manager_capacity_status_read_data.ppif`;
- residue alignment that removes only the covered generated capture residue.

The implementation remains fail-closed for alternate capture scopes, explicit
output widths, alternate completion sources, unsupported interleaving policies,
`RLAST`, bursts, and multi-beat reassembly.

## Rollback Boundary

If `.47` exposes an unexpected lowerer limitation, the safe rollback is to keep
the `.45` parser/report metadata and structural sample intact while leaving
`read_data.generated_behavior: false` and `generated_read_data_capture` in
residue. That preserves the public AST/structural contract without claiming
HDL behavior.

## Explicit Deferrals

This audit does not select behavior for:

- `RLAST`-driven completion;
- burst or multi-beat read-data assembly;
- different-ID read-data reassembly queues;
- same-ID concrete-ID issue-order queues;
- subordinate read-data reordering-depth modeling;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.
