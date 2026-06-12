# IAL2 PPIF Valid-Ready Bundle First Slice

Status: shipped bounded behavior for multi-channel `.ppif` Valid-Ready bundles.

Task tree:
[docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md](tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md).

Contract selection:
[docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md](IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md).

Runnable sample:
[ppif/axi_aw_w_valid_ready_bundle.ppif](../ppif/axi_aw_w_valid_ready_bundle.ppif).

## Scope

This slice implements the first multi-channel `.ppif` bundle path for
Valid-Ready channel monitors. A `.ppif` file may now contain more than one
`(valid-ready-channel ...)` clause when each channel object name is unique.

Each channel still lowers independently through the required chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0
```

The bundle path does not select a wrapper/top actor and does not perform
direct `.ppif` to `.fsm` lowering.

## Source Shape

The checked-in sample uses this shape:

```text
(protocol-platform-intent axi_aw_w_valid_ready_bundle
  (profile axi4)
  (source
    (object axi-valid-ready-aw-w-bundle)
    (anchor (document IHI0022_L_2025-08) (section A3.2) (page A3-40)))
  (valid-ready-channel axi_aw
    (source
      (object axi-valid-ready-aw)
      (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
    (channel AW)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid awvalid)
    (ready awready)
    (payload
      (awaddr width 32)
      (awlen width 8)))
  (valid-ready-channel axi_w
    (source
      (object axi-valid-ready-w)
      (anchor (document IHI0022_L_2025-08) (section A3.2.1) (page A3-40)))
    (channel W)
    (role manager-to-subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (valid wvalid)
    (ready wready)
    (payload
      (wdata width 32)
      (wstrb width 4))))
```

The top-level `(source ...)` names the aggregate source object. A
channel-local `(source ...)` may refine the anchors for one channel. If a
future source omits channel-local source metadata, the aggregate report marks
that channel source attribution as inherited from the top-level source.

## Report Surface

`--emit-schedule-json` emits an aggregate IAL2 report:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The report schema is:

```text
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

The stable first-slice bundle fields include:

- `bundle`: protocol, channel count, channel object names, and inherited-source
  count;
- `channels[]`: channel object name, source attribution, source object,
  target-channel metadata, bindings, generated artifacts, transfer-fire
  condition, generated assertions, and channel-local residue;
- `generated_artifacts.ial1.items[]`: generated `.isf` review artifacts;
- `generated_artifacts.ial0.items[]`: generated `.fsm` review artifacts; and
- `generated_artifacts.hdl_entry`: explicit evidence that no bundle HDL entry
  is selected in this slice.

## CLI Behavior

`--outdir` materializes every generated channel `.isf` and `.fsm` review
artifact, then stops before HDL generation:

```bash
./bin/fsmgen --outdir generated ppif/axi_aw_w_valid_ready_bundle.ppif
```

For the sample, this writes:

```text
generated/axi_aw_valid_ready_monitor.isf
generated/axi_aw_valid_ready_monitor.fsm
generated/axi_w_valid_ready_monitor.isf
generated/axi_w_valid_ready_monitor.fsm
```

`--check --json` succeeds when the bundle parses and all generated
channel-level review artifacts lower internally:

```bash
./bin/fsmgen --strict --check --json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The check report keeps `source.resolved_path` on the public `.ppif` input and
reports the channel count through the bounded result summary. No HDL is
emitted by check mode.

Default HDL generation fails closed for a bundle:

```bash
./bin/fsmgen ppif/axi_aw_w_valid_ready_bundle.ppif
```

The diagnostic tells the user to use `--emit-schedule-json` or `--outdir`
until a bundle HDL entry owner is selected.

`--verify-hdl` also fails closed for a bundle, including with `--outdir`,
because no bundle HDL entry exists to verify yet.

Aggregate normalized semantic JSON also fails closed:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The failure is machine-readable JSON and states that aggregate semantic JSON
needs a later owner. The single-channel `.ppif` semantic JSON behavior remains
unchanged.

## Boundaries

This slice is monitor-only. It does not implement a full AXI manager, AXI
transaction IDs, outstanding-window scheduling, response matching, bursts,
cross-channel dependency rules, wrapper/top actor generation, default bundle
HDL generation, aggregate semantic JSON, platform placement clauses, or
protocol-profile suffix aliases.

## Validation

Focused coverage lives in
[t/1436-ial2-ppif-parser-cli.t](../t/1436-ial2-ppif-parser-cli.t). It proves
the existing single-channel path still works and covers the bundle parser,
bundle report, review-artifact materialization, check JSON, default HDL
fail-closed diagnostic, semantic JSON fail-closed diagnostic, and duplicate
channel-object-name rejection.
