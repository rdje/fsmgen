# AXI IAL2 Manager Read Data Metadata First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.45`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implemented the parser/report metadata boundary selected by
[docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md).
It does not generate `RDATA`/`RRESP` capture logic yet.

## Shipped Public Syntax

The existing `manager-capacity-status` object now accepts one optional
`read-data` clause with one read family arm:

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
      (status-output axi0_r1_rresp))))
```

The clause is explicit. A generated read `RID` response-demux arm does not
implicitly request data capture. `completion-source response-demux` means the
generated per-transaction read demux completion pulse is the future validity
strobe for that transaction's data/status outputs.

The first syntax is single-beat only. It excludes `RLAST`, burst assembly,
multi-beat reassembly, explicit output widths, and alternate interleaving
policies.

## Static Validation

The parser and generator now fail closed on:

- duplicate or malformed `read-data` clauses;
- unsupported family arms other than `read`;
- missing or duplicate read-data subclauses;
- capture scopes other than `single-beat`;
- completion sources other than `response-demux`;
- missing or malformed `data-signal NAME (width N)` entries;
- non-positive `RDATA` widths;
- `status-signal` widths other than `2`;
- interleaving policies other than `single-beat-by-rid`;
- missing, duplicate, or unknown transaction bindings;
- transaction bindings that do not exactly cover the generated read
  response-demux auto transactions;
- explicit transaction output widths or unsupported transaction clauses;
- input/output names that collide with clock, reset, events, ID signals,
  status outputs, generated auto-ID state, generated read demux completion
  signals, storage, or other read-data names;
- missing generated read response-demux prerequisites.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

For the checked-in sample, the report includes structural `read_data`
metadata:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_completion_pulse
    data_signal: axi0_rdata
    data_signal_width: 32
    data_signal_direction: generated_input
    status_signal: axi0_rresp
    status_signal_width: 2
    status_signal_direction: generated_input
    interleaving_policy: single_beat_by_rid
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_rdata
        status_output: axi0_r0_rresp
        data_width: 32
        status_width: 2
      - transaction: r1
        completion_signal: axi0_r1_complete
        data_output: axi0_r1_rdata
        status_output: axi0_r1_rresp
        data_width: 32
        status_width: 2
  residue:
    - generated_read_data_capture
    - rlast_completion
    - bursts
    - multi_beat_read_data_reassembly
```

`generated_behavior` is deliberately `false`: the report is an AST/structural
contract, not a generated capture claim.

## Generated Behavior

Generated `.isf`, `.fsm`, and SystemVerilog behavior remain unchanged from the
read response-demux sample:

- `axi0_rdata` and `axi0_rresp` are not generated IAL1 inputs yet;
- transaction data/status outputs are not generated yet;
- no read-data capture rules, `.fsm` assignments, or HDL signals are emitted;
- read capacity release and auto-ID release remain driven by the generated
  read response-demux completion pulses shipped earlier.

The checked-in focused tests compare generated IAL1 and IAL0 artifacts against
the read response-demux sample and prove `--verify-hdl` still succeeds.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_data.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_read_data.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_read_data
```

## Explicit Residue

Generated `RDATA`/`RRESP` input declarations, per-transaction data/status
outputs, generated data-capture rules, `.fsm` assignments, HDL reachability,
`RLAST`, burst/last-beat tracking, multi-beat read-data reassembly,
different-ID read-data interleaving, per-ID response queues, queued/blocking
policy, profile aliases, full AXI manager syntax, direct backend lowering, and
VHDL backend/reroute behavior remain future exact-owner work.

Follow-on: `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` is the next readiness audit
for generated single-beat read-data capture behavior.
