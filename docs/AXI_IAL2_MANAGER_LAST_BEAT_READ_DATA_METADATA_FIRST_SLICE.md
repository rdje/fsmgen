# AXI IAL2 Manager Last-Beat Read-Data Metadata First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.58`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the parser/report metadata boundary selected by
[docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md).
It does not generate last-beat `RDATA`/`RRESP` capture logic yet.

## Shipped Public Syntax

The existing `manager-capacity-status` `read-data` read arm now accepts the
selected last-beat capture scope:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The shipped single-beat form remains valid and unchanged:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    ...))
```

`capture-scope last-beat` is valid only when the read `response-demux` arm is
generated and uses `response-scope burst-last`. The generated response-demux
last-beat completion pulse is the future validity strobe for the matching
transaction's last-beat data/status outputs.

`status-policy last-beat` is mandatory for this scope. The contract reports
the `RRESP` value present on the matched `RID` beat whose `RLAST` signal
completes the transaction. It does not aggregate all burst `RRESP` values.

## Static Validation

The parser and generator now fail closed on:

- capture scopes other than `single-beat` or `last-beat`;
- `capture-scope single-beat` combined with `status-policy`;
- `capture-scope last-beat` without `status-policy last-beat`;
- `capture-scope last-beat` without generated read response-demux metadata
  using `response_scope burst_last`;
- `capture-scope single-beat` without generated read response-demux metadata
  using `response_scope single_beat`;
- completion sources other than `response-demux`;
- missing or malformed `data-signal NAME (width N)` entries;
- non-positive `RDATA` widths;
- `status-signal` widths other than `2`;
- interleaving policies other than `single-beat-by-rid` for single-beat scope
  and `last-beat-by-rid` for last-beat scope;
- missing, duplicate, or unknown transaction bindings;
- transaction bindings that do not exactly cover the generated read
  response-demux auto transactions;
- unsupported transaction clauses, explicit transaction output widths,
  valid/length/per-beat output clauses, depth/count clauses, status
  aggregation clauses, or full-reassembly clauses;
- input/output names that collide with clock, reset, events, ID signals,
  status outputs, generated auto-ID state, generated read-demux completion
  signals, storage, or other read-data names.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

For the checked-in last-beat sample, the report includes structural
`read_data` metadata:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    data_signal: axi0_rdata
    data_signal_width: 32
    data_signal_direction: generated_input
    status_signal: axi0_rresp
    status_signal_width: 2
    status_signal_direction: generated_input
    status_policy: last_beat
    status_aggregation: none
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    beat_storage: none
    valid_output: none
    length_output: none
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_last_rdata
        status_output: axi0_r0_last_rresp
        data_width: 32
        status_width: 2
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_last_rdata
        status_output: axi0_r1_last_rresp
        data_width: 32
        status_width: 2
  residue:
    - generated_last_beat_read_data_capture
    - multi_beat_read_data_reassembly
    - per_beat_outputs
    - rresp_aggregation
    - arlen_or_beat_count_validation
```

`generated_behavior` is deliberately `false`: this slice is a structural
contract and validation boundary, not a generated capture behavior claim.

## Generated Behavior

Generated `.isf`, `.fsm`, and SystemVerilog behavior remain unchanged from
the generated burst-last response-demux sample:

- `axi0_rdata` and `axi0_rresp` are not generated IAL1 inputs for the new
  last-beat sample yet;
- transaction last-beat data/status outputs are not generated yet;
- no last-beat read-data capture rules, `.fsm` assignments, or HDL signals are
  emitted yet;
- read capacity release and read auto-ID release remain driven by generated
  burst-last response-demux completion pulses;
- the existing single-beat read-data behavior remains generated and unchanged.

The focused tests compare generated IAL1 and IAL0 artifacts against the
burst-last response-demux sample and prove `--verify-hdl` still succeeds for
the last-beat sample.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_data_last_beat.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_last_beat.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-last-beat-read-data.sv ppif/axi_manager_capacity_status_read_data_last_beat.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_read_data_last_beat
```

## Explicit Residue

Generated last-beat `RDATA`/`RRESP` input declarations, per-transaction
last-beat data/status outputs, generated capture rules, `.fsm` assignments,
HDL reachability for those outputs, full multi-beat read-data reassembly,
per-beat outputs, `RRESP` aggregation across all beats, `ARLEN` or beat-count
validation, missing/extra beat validation, per-ID response queues, full AXI
manager syntax, direct backend lowering, and VHDL backend/reroute behavior
remain future exact-owner work.

## Next Owner

`IAL2-FEATURE-COMPLETENESS-FRONTIER.59` owns the readiness audit for generated
last-beat `RDATA`/`RRESP` capture behavior. That audit must decide whether the
existing IAL1/IAL0/SystemVerilog substrate can directly carry last-beat data
capture rules, or whether a smaller prerequisite must land first.
