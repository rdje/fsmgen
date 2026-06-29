# IAL2 AHB Multi-Subordinate Decode Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.728`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.728` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.729`, a no-behavior public contract
selection for the first bounded two-subordinate AHB interconnect/decode
surface.

The audit finds that the generated-substrate direction is plausible without a
separate lower-layer repair, but direct implementation is not yet the next
safe slice. The source syntax, child/address-map cardinality, per-subordinate
wiring model, generated artifact naming, report shape, support-accounting
identity, diagnostics, residue migration, validation gates, and rollback
contract need to be selected before parser or generator behavior changes.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The shipped aggregate AHB interconnect sources are:

```text
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect.ahb
```

Both are intentionally singular:

- one `(ahb-requester amba_requester ...)` object;
- one `(ahb-subordinate ahb_lite_subordinate ...)` object;
- one `(ahb-interconnect ahb_tb ...)` object;
- one `(subordinate regs ahb_lite_subordinate)` child binding;
- one static address-map window named `regs`;
- scalar subordinate-side interconnect wiring such as `HSEL_REGS`,
  `HADDR_REGS`, `HREADYOUT_REGS`, `HRESP_REGS`, and `HRDATA_REGS`; and
- report topology `one_requester_one_subordinate_static_window_interconnect`.

Live probes confirm the boundary remains fail-closed:

```text
extra ahb-subordinate object:
  AHB interconnect requires exactly one requester, one subordinate, and one
  interconnect object in this slice

extra subordinate child:
  duplicate (subordinate ...) clause

extra address-map window:
  requires exactly one (window ...) clause in this slice
```

The aggregate `.ahb` alias report keeps these residue IDs:

```text
ahb_multi_subordinate_decode_deferred
ahb_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

`ahb_multi_subordinate_decode_deferred` is the first aggregate-interconnect
residue to address after the `.726` alias shipment.

## Implementation Readiness

The current AHB implementation is not list-shaped yet. The parser records one
subordinate child in a scalar `children.subordinate` field, requires exactly
one address-map window, and validates that the window name matches that single
subordinate child instance. The generator selects
`address_map.windows[0]`, emits one subordinate select/local-address output,
uses scalar response/data input fields, builds a three-child aggregate top,
and reports `supported_subordinate_cardinality => 1`.

APB multi-peripheral interconnect/decode is useful precedent, but not reusable
AHB behavior by itself. It already demonstrates the list-shaped mechanics that
AHB needs to select explicitly:

- two-or-more child entries in an array;
- one static window per child;
- duplicate child/window/object rejection;
- missing-window rejection;
- non-overlap checks;
- deterministic generated instance names that avoid top-port collisions;
- generated interconnect `.isf`/`.fsm` loops over endpoints;
- response muxing over selected endpoints; and
- report/support-accounting fields for multi-endpoint topology.

AHB endpoint generation can already produce unique subordinate artifacts if
the source uses distinct subordinate object names, because the subordinate
generator derives its generated `.isf` and `.fsm` artifact names from the
object/actor name. That makes a bounded two-subordinate implementation
plausible after contract selection, while also showing why the first contract
must require unique subordinate object names or an explicit artifact-naming
policy.

## Contract Questions For `.729`

`.729` should select the exact public contract before implementation. It must
decide:

- whether the first behavior-bearing source is generic `.ppif`, matching
  `.ahb`, or both in one implementation slice;
- whether the first widened public shape is exactly two subordinate endpoints,
  or a two-or-more syntax with only two support-accounted fixtures;
- whether subordinate children remain repeated `(subordinate INSTANCE OBJECT)`
  clauses or move to an explicit list form;
- whether top-level subordinate objects must have unique object names and
  unique generated artifact names;
- whether address-map windows must be exactly one per subordinate child and
  whether source order defines decode priority;
- whether non-overlap rejection is mandatory in the first AHB widening;
- how per-subordinate select, local address, ready-out, response, and read-data
  wiring is represented without overloading the current scalar
  `subordinate-*` fields;
- how decoded signal names should appear in generated `ahb_interconnect.isf`,
  generated `ahb_interconnect.fsm`, aggregate `ahb_tb.fsm`, and HDL;
- whether unmapped active-transfer ERROR remains interconnect-owned and
  two-cycle;
- whether one-bit subordinate `HRESP` remains the only supported subordinate
  response width;
- which report topology, address-map, endpoint, generated-instance,
  response-mux, and width-policy fields identify the widened behavior;
- which support-accounting identities and coverage keys identify generic
  `.ppif` and profile-alias `.ahb` fixtures;
- which residue ID is removed or narrowed when the behavior ships; and
- which focused parser/generator/CLI/diagnostic tests and rollback steps are
  mandatory.

## Selected Next Owner

`.729` owns public contract selection for the bounded two-subordinate AHB
interconnect/decode surface. It should not implement parser or generator
behavior. It should leave direct implementation to the next exact owner after
the contract is selected, unless the contract audit finds a narrower
prerequisite.

The likely implementation shape after `.729`, if selected, is a pair of
support-accounted public sources such as:

```text
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_two_subordinate.ahb
```

Those names are candidates only; `.729` must select or reject them.

## Explicit Non-Goals

Do not add multi-subordinate behavior in `.728`. Do not add parser support for
multiple subordinate objects, multiple subordinate child bindings, or multiple
address-map windows. Do not add multiple requesters, arbitration, bus
matrices, optional/property-gated AHB signals, burst `SEQ` continuation,
byte-lane/narrow-transfer behavior, legacy two-bit subordinate `HRESP`
compatibility, direct backend behavior, verification-output generation,
backend-language variants, AXI, APB, or VHDL behavior.

