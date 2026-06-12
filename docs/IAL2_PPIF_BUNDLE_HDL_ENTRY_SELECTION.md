# IAL2 PPIF Bundle HDL Entry Selection

Status: selected future HDL entry contract; no implementation in this slice.

Task tree:
[docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.md](tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.md).

Builds on:

- [docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md](IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md)
- [docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md)

## Selection

Future default HDL generation for a multi-channel `.ppif` Valid-Ready bundle
must use an aggregate wrapper/top entry. It must not select the first generated
channel `.fsm` as the HDL root.

The selected future contract is:

- keep every authored `valid-ready-channel` as its own generated channel
  monitor;
- add one explicit aggregate wrapper/top actor whose public module name is the
  top-level `protocol-platform-intent` name, sanitized by the same naming rules
  used for generated artifacts;
- expose the aggregate wrapper as reviewable generated IAL1 and IAL0 artifacts
  before HDL emission;
- instantiate or compose all generated channel monitors under that wrapper;
- form the wrapper public ports from the union of channel monitor ports;
- share identical clock/reset ports once when their signal names and reset
  policies match;
- fail closed on ambiguous same-name port conflicts, incompatible reset
  policies, or channel artifact collisions; and
- keep the bundle report's `generated_artifacts.hdl_entry` explicit about the
  selected aggregate entry.

This preserves the mandatory lowering chain:

```text
.ppif / IAL2 -> generated .isf / IAL1 -> generated .fsm / IAL0 -> HDL
```

The wrapper is a monitor bundle only. It does not add AXI manager transaction
semantics, ID allocation, ordering, outstanding windows, bursts, response
matching, or cross-channel dependency enforcement.

## CLI Consequences

A future implementation leaf should keep the current non-HDL modes stable:

- `--emit-schedule-json` continues to emit the aggregate bundle report.
- `--check --json` continues to validate parsing/lowering and report aggregate
  metadata without writing HDL.
- `--emit-semantic-json` continues to emit the aggregate PPIF bundle semantic
  root without writing HDL.

For HDL modes, the future implementation should change behavior only after the
aggregate wrapper review artifacts exist:

- default generation may write the aggregate wrapper HDL root;
- `--verify-hdl` may verify that aggregate wrapper HDL root;
- `--outdir` should materialize every per-channel review artifact and the
  aggregate wrapper review artifacts; and
- no mode may silently hide or drop any generated channel monitor.

## Why Not First Channel Wins

Selecting the first generated channel root would produce syntactically valid
HDL for only part of the authored intent. That would make the report, mdBook,
and emitted HDL disagree: the source says "bundle", while the HDL would only
represent one channel. The selected aggregate wrapper rule keeps all channels
visible and reviewable.

## First Implementation Boundary

The first HDL-entry implementation should be narrow:

- accept only the existing Valid-Ready bundle shape;
- require unique generated artifact names;
- support shared identical clock/reset only;
- fail closed on incompatible duplicate top-level port names;
- emit no cross-channel assertions beyond existing per-channel monitor
  assertions; and
- leave full AXI manager behavior to a later rule-engine owner.

Any wider behavior needs a new exact task-tree leaf before code changes.
