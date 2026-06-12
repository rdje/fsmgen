# AXI IAL2 Manager Capacity/Status PPIF First Slice

Status: public `.ppif` parser/CLI slice for one AXI manager capacity/status
object shipped.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md)

Runnable sample:
[ppif/axi_manager_capacity_status.ppif](../ppif/axi_manager_capacity_status.ppif).

## Public Source Shape

The first public AXI manager capacity/status source is exactly one
`(manager-capacity-status NAME ...)` object under the generic
`(protocol-platform-intent ...)` root:

```text
(protocol-platform-intent axi_manager_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A1.2) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A5.1) (page A5-1)))
  (manager-capacity-status axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-max-pending 4)
    (write-max-pending 2)
    (submit-policy try)
    (read-submit axi0_read_submit)
    (read-complete axi0_read_complete)
    (write-submit axi0_write_submit)
    (write-complete axi0_write_complete)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available))))
```

The PPIF adapter maps the hyphenated source clauses to the structured
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` contract before
generation. The mandatory lowering chain remains:

```text
IAL2 .ppif -> generated .isf -> generated .fsm -> SystemVerilog
```

## CLI Behavior

The sample participates in the existing public `.ppif` CLI path:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status.ppif
```

`--emit-schedule-json` emits the IAL2 report schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

`--outdir` writes the generated review artifacts:

```text
generated/axi0_capacity_status.isf
generated/axi0_capacity_status.fsm
```

Default HDL generation and `--verify-hdl` use the generated `.fsm` entry and
emit the `axi0_capacity_status` SystemVerilog module.

## Public Accounting

The new sample is a supported regression-corpus entry:

```text
intent.ppif_axi_manager_capacity_status
```

Check JSON and normalized semantic JSON keep `source.resolved_path` on the
public `.ppif` source. The normalized semantic payload still reports the
generated `.fsm` semantic root because this slice intentionally preserves the
reviewable `IAL2 -> IAL1 -> IAL0` chain.

## Diagnostics And Residue

The parser fails closed on:

- mixed `valid-ready-channel` and `manager-capacity-status` object families,
- multiple manager capacity/status objects,
- missing required manager clauses,
- unsupported status clauses,
- unsupported `submit-policy` values,
- unsupported ID, ordering, response, burst, channel-expansion, or actor-name
  clauses,
- generator-level identifier and name-collision errors.

This is still a capacity/status shell, not a full AXI manager. Profile aliases
such as `.axi`, ID allocation, same-ID ordering, different-ID interleaving,
response matching, burst/last-beat tracking, queued/blocking policy behavior,
HDL blocked-reason outputs, and VHDL backend behavior remain future
task-tree-owned work.

## Validation

The slice is covered by:

- `t/1436-ial2-ppif-parser-cli.t`,
- `t/1437-axi-ial2-manager-capacity-status-generator.t`,
- `t/297-capability-manifest.t`,
- `t/317-language-surface-contract.t`,
- `t/301-check-json-supported-corpus.t`,
- `t/303-normalized-semantic-json-supported-corpus.t`.
