# IAL2 PPIF Valid-Ready Bundle Contract Selection

Status: contract selection slice. The bounded report/review-artifact subset is
implemented by
[docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md),
and aggregate semantic JSON is implemented by
[docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md).
The HDL entry contract is selected by
[docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md)
and first implemented by
[docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md).

Task tree:
[docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.md](tasks/IAL2-PPIF-VALID-READY-BUNDLE-CONTRACT-SELECTION.md).

Decision record:
[docs/decisions/0017-ppif-valid-ready-bundle-contract.md](decisions/0017-ppif-valid-ready-bundle-contract.md).

Readiness prerequisite:
[docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md](IAL2_PPIF_MULTI_VALID_READY_READINESS.md).

## Selection

Multi-object `.ppif` Valid-Ready support uses an aggregate
**bundle contract** over per-channel generated artifacts.

The selected contract is:

- one `.ppif` source remains one IAL2 protocol/platform intent;
- each authored `(valid-ready-channel ...)` remains one channel-level intent
  object;
- each channel object emits its own reviewable generated `.isf` actor and its
  own generated `.fsm` artifacts;
- the PPIF result adds aggregate `items[]` arrays and an aggregate IAL2 report
  schema; and
- no direct `.ppif -> .fsm` shortcut and no hidden multi-actor `.isf` file are
  introduced.

The current implementation selects an aggregate wrapper/top `.fsm` as the HDL
entry for the tracked AW/W Valid-Ready bundle sample. Report emission, check
JSON, review-artifact materialization, aggregate semantic JSON, default
SystemVerilog generation, and `--verify-hdl` are implemented for that bounded
shape.

## Source Shape

The future source remains Lispish and protocol/platform-generic:

```text
(protocol-platform-intent axi_valid_ready_bundle
  (profile axi4)
  (source
    (object axi-valid-ready-bundle)
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

The top-level `(source ...)` clause remains required and names the aggregate
intent source object. A channel-local `(source ...)` clause may refine source
anchors for that channel. When a channel-local source is omitted, the future
report must mark the channel source as inherited from the aggregate source
rather than silently pretending channel-specific evidence exists.

Channel object names must be unique within the file. Interface signal names
must remain unique within each generated channel monitor; broader cross-channel
signal-sharing rules are deferred until a bundle implementation owner maps the
exact rule.

## Aggregate Result Shape

The future multi-channel PPIF adapter result shall use a new aggregate kind:

```text
layer = IAL2
kind  = protocol_intent.valid_ready_bundle
```

The aggregate report schema shall be:

```text
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

The aggregate result shall expose arrays instead of pretending there is one
generated artifact:

```text
generated_ial1 = {
  format = isf
  items[] = {
    object_name
    channel
    name
    text
  }
}

generated_ial0 = {
  format = fsm
  items[] = {
    object_name
    channel
    files
    entry_artifact
  }
}
```

The single-object `.ppif` result shape remains unchanged until an explicit
compatibility owner migrates or aliases it. Multi-object bundle support must
not break callers that use the current single-channel `generated_ial1`,
`generated_ial0`, `generated_ial1_schedule_report`, or
`valid_ready_channel.v1` report fields.

## Report Contract

The bundle report shall preserve the existing first-slice layering evidence
and add aggregate channel entries:

```text
schema
layering
source_object
bundle
channels[]
generated_artifacts
unsupported_residue
```

`source_object` describes the aggregate `protocol-platform-intent` source.

`bundle` records the protocol/profile, channel count, channel object names,
and whether any channel source was inherited from the aggregate source.

Each `channels[]` entry records:

- channel object name;
- source object and source-attribution scope;
- protocol channel family and role;
- clock, reset, valid, ready, and payload bindings;
- generated IAL1 and IAL0 artifact names for that channel;
- transfer fire condition;
- monitor/assertion summary; and
- channel-local unsupported residue.

`generated_artifacts` contains aggregate `ial1.items[]` and `ial0.items[]`
arrays. The current bounded HDL entry is an aggregate wrapper/top `.fsm`
selected by `generated_artifacts.hdl_entry`.

`unsupported_residue` remains explicit for bundle-level omissions. AXI
transaction IDs, outstanding-window scheduling, response matching, bursts,
cross-channel dependency rules, and full AXI manager behavior remain residue
outside this bundle monitor contract.

## CLI Contract

Multi-channel `.ppif` behavior follows these rules:

- `--emit-schedule-json` emits the aggregate IAL2 bundle report and writes no
  files.
- `--outdir DIR` writes every generated channel `.isf`, generated channel
  `.fsm`, and aggregate wrapper/top `.fsm` review artifact.
- default HDL generation for the tracked AW/W bundle uses the aggregate
  wrapper/top entry.
- `--verify-hdl` validates that aggregate wrapper/top HDL.
- `--check --json` may report successful PPIF bundle parsing/lowering if all
  generated channel artifacts are internally valid.
- `--emit-semantic-json` emits an aggregate PPIF bundle semantic root with
  `semantic.module.source_root_kind = ppif_bundle` and a
  `semantic.protocol_intent_bundle` child, rather than returning one arbitrary
  channel.

This contract deliberately avoids "first channel wins" behavior. Selecting an
arbitrary generated `.fsm` as the HDL or semantic entry would hide the rest of
the authored intent and create review drift.

## Implementation Prerequisites

The bounded behavior leaves implement the report/check/outdir, aggregate
semantic JSON, and aggregate wrapper/top HDL entry subsets of this selection.
Future widening leaves still need the remaining parts of this contract when
adding broader AXI manager behavior:

- parser changes for repeated `valid-ready-channel` clauses and optional
  channel-local `source` clauses;
- a bundle generator or orchestration module that calls the existing
  `ValidReadyChannel` generator per channel without changing its single-object
  API;
- aggregate report construction with stable `channels[]` and artifact arrays;
- CLI handling for aggregate report mode, review-artifact materialization,
  aggregate semantic JSON, and wrapper/top HDL modes;
- focused tests that prove the current single-object behavior still works; and
- mdBook examples that state which bundle CLI modes are shipped by each future
  code leaf.

## Current User-Facing State

Users can use the shipped one-channel `.ppif` path today. Users can also use
the bounded multi-channel bundle path for aggregate reports, check JSON,
aggregate semantic JSON, generated `.isf`/`.fsm` review artifacts, aggregate
wrapper/top SystemVerilog generation, and `--verify-hdl` on the tracked AW/W
bundle shape.
