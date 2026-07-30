# 0027 — HDL instance identifiers use a portable origin-aware policy

- Date: 2026-07-30
- Type: architecture
- Status: accepted and implemented by `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2`

## Context

AHB once generated the SystemVerilog keyword `interconnect` as a child
instance label and repaired that one seed locally as `fabric`. The APB
multi-peripheral generator still emits `apb_interconnect interconnect (` and
fails Verilator. Focused probes reproduce the same late target-parser failure
for direct C4 aliases, reusable-library use aliases, and spawn aliases.

Every relevant parser/helper validates only the simple identifier spelling,
and both structural emitters insert the resulting label verbatim. The VHDL
emitter likewise accepts the VHDL keyword `process` and renders it as an entity
label. Local collision helpers do not address either target's keyword set.

## Decision

FSMGen will use one shared portable child-instance identifier policy:

- the simple unescaped spelling remains `[A-Za-z_][A-Za-z0-9_]*`;
- one registry reserves the union of keywords across all shipped HDL targets,
  applying VHDL's case-insensitive rule and Verilog-family case sensitivity;
- author-owned labels fail closed at the nearest source boundary with an
  origin- and target-aware diagnostic; they are never silently renamed;
- generator-owned labels are allocated deterministically: a keyword seed uses
  `<desired>_instance`, an ordinary collision uses `<desired>_<role>`, and
  subsequent collisions add `_2`, `_3`, and so on;
- allocation reserves language keywords, declared top ports, and prior sibling
  labels while preserving every legal non-colliding label byte-for-byte;
- public reports keep authored and generated identities distinct wherever an
  authored identity exists; and
- structural emitters validate again as a defense against callers that build
  `StructuralRTLIR` directly.

FSMGen will not auto-escape instance labels. Verilog-family escaped identifiers
and VHDL extended identifiers have different syntax, and backend-specific
escaping would make wiring/report identity depend on the selected target.

## Consequences

- APB's generated interconnect instance becomes `interconnect_instance`; its
  generated composition wiring and public generated-instance report fields
  change together and require explicit regression coverage.
- Existing legal AHB `fabric` and fixed AXI labels remain unchanged.
- Direct C4, spawn, reusable-library, and ATL authors receive an early rename
  diagnostic instead of invalid target HDL.
- The policy is conservative for a name that is legal in one target but a
  keyword in another; this is deliberate so backend-neutral intent retains one
  stable structural identity.
- Module/top/port/net/parameter identifier families remain outside this
  decision's implementation slice and require separate owners if audited.

## Implementation

`FSM::Support::HDLInstanceIdentifierPolicy` now owns the SystemVerilog and
VHDL-2008 keyword registries, authored-label diagnostic, and generated-label
allocator. Direct C4, spawn, reusable-library, ATL, APB/AHB normalization, and
both structural emitters call the shared policy. APB public composition/report
identity is `interconnect_instance`; AHB `fabric` and fixed AXI labels remain
unchanged. Focused regressions include public APB Verilator lint plus Yosys
synthesis and direct VHDL-emitter defense coverage.
