# IAL2 PPIF Bundle HDL Entry First Slice

Status: shipped bounded aggregate wrapper/top HDL entry for the tracked
multi-channel `.ppif` Valid-Ready bundle.

Task tree:
[docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md](tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md).

Builds on:

- [docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md)

Runnable sample:
[ppif/axi_aw_w_valid_ready_bundle.ppif](../ppif/axi_aw_w_valid_ready_bundle.ppif).

## Scope

The existing AW/W Valid-Ready bundle sample now has a selected aggregate HDL
entry. The adapter generates:

- one generated `.isf` monitor per channel;
- one generated channel `.fsm` per channel;
- one generated aggregate wrapper/top `.fsm` named from the top-level
  `protocol-platform-intent`; and
- SystemVerilog from that wrapper/top through the existing composition path.

The mandatory lowering chain remains intact:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The selected HDL entry report is:

```text
generated_artifacts.hdl_entry.selected       = 1
generated_artifacts.hdl_entry.kind           = aggregate_wrapper_top
generated_artifacts.hdl_entry.entry_artifact = axi_aw_w_valid_ready_bundle.fsm
generated_artifacts.hdl_entry.module_name    = axi_aw_w_valid_ready_bundle
```

The wrapper shares identical system ports once (`clk`, `rst_n`) and exposes the
union of channel-level public data/control ports. Duplicate non-system wrapper
port names, incompatible reset policies, and generated artifact collisions fail
closed.

## CLI Behavior

The aggregate report remains available without writing HDL:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The report includes the selected `aggregate_wrapper_top` HDL entry and the
per-channel child artifacts.

Default SystemVerilog generation uses the aggregate wrapper/top:

```bash
./bin/fsmgen --output bundle.sv ppif/axi_aw_w_valid_ready_bundle.ppif
```

`--outdir` materializes all review artifacts before HDL generation:

```bash
./bin/fsmgen --outdir generated --output bundle.sv ppif/axi_aw_w_valid_ready_bundle.ppif
```

For the sample, this writes:

```text
generated/axi_aw_valid_ready_monitor.isf
generated/axi_aw_valid_ready_monitor.fsm
generated/axi_w_valid_ready_monitor.isf
generated/axi_w_valid_ready_monitor.fsm
generated/axi_aw_w_valid_ready_bundle.fsm
```

`--verify-hdl` validates the aggregate wrapper/top HDL:

```bash
./bin/fsmgen --outdir generated --output bundle.sv --verify-hdl ppif/axi_aw_w_valid_ready_bundle.ppif
```

`--check --json` and `--emit-semantic-json` remain non-HDL modes. They keep the
public `.ppif` source path in their reports and expose the aggregate bundle
summary without writing HDL.

## Wrapper Shape

The generated wrapper/top `.fsm` is a composition root whose public name is the
top-level PPIF intent name. For the sample, it contains a top root with
composition children for the AW and W generated channel monitors:

```text
(?top:axi_aw_w_valid_ready_bundle
  (?ports:public_io
    clk
    rst_n
    =awvalid<
    =awready<
    =awaddr<32
    =awlen<8
    =axi_aw_valid_ready_monitor_done>
    =wvalid<
    =wready<
    =wdata<32
    =wstrb<4
    =axi_w_valid_ready_monitor_done>)
  (?fsmc:axi_aw_valid_ready_monitor)
  (?fsmc:axi_w_valid_ready_monitor))
```

The SystemVerilog output contains the two channel monitor modules plus the
`axi_aw_w_valid_ready_bundle` wrapper module that instantiates both children.

## Verifier Boundary

The generated per-channel assertions keep sampled-value expressions such as
`$past(awvalid)` inline in assertion property text. Sampled-value helpers are
not emitted as unclocked combinational `assign` wires, so the generated
SystemVerilog remains accepted by the current `--verify-hdl` gate.

## Boundaries

This slice is still monitor-only. It does not implement full AXI manager
behavior, transaction IDs, outstanding windows, ordering, interleaving,
response matching, bursts, cross-channel dependency rules, platform placement
clauses, `.pif`/`.ppi` aliases, or protocol-profile suffix aliases.

## Validation

Focused coverage lives in
[t/1436-ial2-ppif-parser-cli.t](../t/1436-ial2-ppif-parser-cli.t). The test
covers the adapter report, aggregate schedule JSON, `--outdir`, default HDL,
aggregate semantic JSON, sampled-value verifier hygiene, and `--verify-hdl`.

The sampled-value helper pruning is also covered by the existing generated
assertion tests:

- [t/1411-isf-assert-emit.t](../t/1411-isf-assert-emit.t)
- [t/1412-isf-property-implication.t](../t/1412-isf-property-implication.t)
