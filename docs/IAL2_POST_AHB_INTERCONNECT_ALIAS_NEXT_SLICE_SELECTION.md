# IAL2 Post AHB Interconnect Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.727`

Date: 2026-06-29

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.727` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.728`, a no-behavior readiness audit for
bounded multi-subordinate AHB interconnect/decode.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Shipped AHB State

The shipped public AHB IAL2 entrypoints are:

```text
ppif/ahb_requester.ppif
ppif/ahb_lite_subordinate.ppif
ppif/ahb_interconnect.ppif
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_interconnect.ahb
```

The aggregate interconnect sources remain bounded to one requester, one
subordinate, one static address window, and generated `ahb_tb`:

```text
amba_requester.isf
ahb_lite_subordinate.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The aggregate `.ahb` alias removes only
`ahb_aggregate_profile_alias_deferred`. Its remaining residue is:

```text
ahb_multi_subordinate_decode_deferred
ahb_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

## Why Multi-Subordinate Readiness Is Next

Multi-subordinate decode is the next structural prerequisite because it is the
first remaining aggregate-interconnect residue. It owns questions that must be
settled before implementation:

- whether the public source shape should allow multiple `(ahb-subordinate ...)`
  objects in the same aggregate source;
- whether `(children ...)` should allow multiple subordinate child bindings;
- how many static address windows are allowed in the first widened contract;
- how window-to-child matching, overlap rejection, priority, local-address
  translation, and decoded select naming should report;
- whether generated `ahb_interconnect.isf`, `ahb_interconnect.fsm`, and
  aggregate `ahb_tb.fsm` can stay list-shaped without lower-layer repair; and
- what support identity, coverage key, fixture path, diagnostics, validation,
  and rollback should be selected.

Current probes confirm the boundary is still singular. `ppif/ahb_interconnect.ahb`
strict-checks successfully as `intent.ahb_profile_alias_interconnect`, while a
temporary source with a second subordinate child is rejected by duplicate
`(subordinate ...)` validation.

## Selected `.728` Scope

`.728` should audit readiness for the first bounded multi-subordinate AHB
interconnect/decode contract without changing behavior. It should read:

- `.726` aggregate `.ahb` alias behavior;
- `.723` aggregate `.ppif` behavior;
- the AHB interconnect parser and generator assumptions around exactly one
  subordinate and one address window;
- APB multi-peripheral interconnect/decode precedent only as a comparison
  source, not as reusable AHB behavior by default;
- current support accounting and capability-manifest surfaces;
- focused AHB tests and diagnostics;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

`.728` should decide whether the next implementation owner can be direct
bounded multi-subordinate behavior or whether a narrower prerequisite is needed
first.

## Explicit Non-Goals

Do not add multi-subordinate behavior in `.727`. Do not add multiple
requesters, arbitration, bus matrices, optional/property-gated AHB signals,
burst `SEQ` continuation, byte-lane/narrow-transfer behavior, legacy two-bit
subordinate `HRESP` compatibility, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, or VHDL
behavior.
