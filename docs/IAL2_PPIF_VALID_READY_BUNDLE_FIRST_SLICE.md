# IAL2 PPIF Valid-Ready Bundle First Slice

Status: shipped bounded behavior for multi-channel `.ppif` Valid-Ready bundles.

Task tree:
[docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md](tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md).

Contract selection:
[docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md](IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md).

Later HDL entry implementation:
[docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md).

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

The original bundle report/review-artifact slice did not select a wrapper/top
actor. The later HDL entry slice now adds a generated aggregate wrapper/top
`.fsm`, while still avoiding direct `.ppif` to `.fsm` lowering.

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
- `generated_artifacts.ial0.items[]`: generated channel `.fsm` review
  artifacts plus the aggregate wrapper/top `.fsm`; and
- `generated_artifacts.hdl_entry`: the selected aggregate wrapper/top HDL
  entry and its per-channel child artifacts.

## CLI Behavior

`--outdir` materializes every generated channel `.isf`, generated channel
`.fsm`, and aggregate wrapper/top `.fsm` review artifact before HDL generation:

```bash
./bin/fsmgen --outdir generated ppif/axi_aw_w_valid_ready_bundle.ppif
```

For the sample, this writes:

```text
generated/axi_aw_valid_ready_monitor.isf
generated/axi_aw_valid_ready_monitor.fsm
generated/axi_w_valid_ready_monitor.isf
generated/axi_w_valid_ready_monitor.fsm
generated/axi_aw_w_valid_ready_bundle.fsm
```

`--check --json` succeeds when the bundle parses and all generated
channel-level review artifacts lower internally:

```bash
./bin/fsmgen --strict --check --json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The check report keeps `source.resolved_path` on the public `.ppif` input and
reports the channel count through the bounded result summary. No HDL is
emitted by check mode.

Default HDL generation now uses the aggregate wrapper/top:

```bash
./bin/fsmgen --output bundle.sv ppif/axi_aw_w_valid_ready_bundle.ppif
```

`--verify-hdl` also uses that aggregate wrapper/top:

```bash
./bin/fsmgen --outdir generated --output bundle.sv --verify-hdl ppif/axi_aw_w_valid_ready_bundle.ppif
```

Aggregate normalized semantic JSON was added by the later bounded semantic
slice:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_w_valid_ready_bundle.ppif
```

It emits an aggregate PPIF bundle semantic root rather than selecting one
generated channel `.fsm`, and now records the selected aggregate wrapper/top
entry. See
[docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md).
The single-channel `.ppif` semantic JSON behavior remains unchanged.

## Boundaries

This slice is monitor-only. It does not implement a full AXI manager, AXI
transaction IDs, outstanding-window scheduling, response matching, bursts,
cross-channel dependency rules, platform placement clauses, or protocol-profile
suffix aliases.

## Validation

Focused coverage lives in
[t/1436-ial2-ppif-parser-cli.t](../t/1436-ial2-ppif-parser-cli.t). It proves
the existing single-channel path still works and covers the bundle parser,
bundle report, review-artifact materialization, check JSON, default HDL
generation, aggregate semantic JSON, `--verify-hdl`, sampled-value verifier
hygiene, and duplicate channel-object-name rejection.
