# IAL2 Post APB Protection Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.657`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB timing/protection residue owner after selected 32-bit
  protection multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.657` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.658`, a readiness audit for generalized
APB multi-peripheral multi-register source shapes after the selected
16/32-bit no-policy, protection, and status/control timing families shipped.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

The APB back-to-back timing frontier now has these selected multi-peripheral
families shipped:

- no-sideband 32-bit one-register two-peripheral timing;
- sideband-aware 32-bit one-register two-peripheral timing;
- sideband-aware 32-bit no-policy `reg0`/`reg1` two-register
  two-peripheral timing;
- sideband-aware 16-bit no-policy `reg0`/`reg1` two-register
  two-peripheral timing;
- sideband-aware 32-bit protection status/control two-peripheral timing;
- sideband-aware 16-bit data16-protection status/control two-peripheral
  timing;
- sideband-aware 16-bit data16-protection protected `reg0`/`reg1`
  two-register two-peripheral timing;
- sideband-aware 32-bit protected `reg0`/`reg1` two-register two-peripheral
  timing.

The most recent `.656` behavior ships exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb`

That selected family uses requester `accepted/busy/status` depth-1 queued
timing, 32-bit APB/register data, `PPROT width 3`, `PSTRB width 4`,
status/control windows at bases `0` and `256`, adjacent setup on both
peripherals, protected `reg0`/`reg1` storage in both peripherals, and
peripheral-owned privileged `PPROT[0]` enforcement.

The live narrowed `apb_additional_back_to_back_policies_deferred` residue now
has no narrower already-selected APB multi-peripheral multi-register
`reg0`/`reg1` timing family left to implement. Its first timing item is
generalized multi-peripheral multi-register timing, followed by deeper queues,
alternate overflow policies, accepted-less requester timing, multiple active
APB transfers, bus matrices, scoreboards, direct backend lowering,
verification-output, backend-language variants, AXI, AHB, and VHDL.

The current guard still intentionally restricts selected multi-peripheral
back-to-back timing to two peripheral completers and exact storage families:
one-register no-sideband, selected 32-bit/data16 no-policy `reg0`/`reg1`,
selected 32-bit/data16 protected `reg0`/`reg1`, and selected 32-bit/data16
protected status/control storage. Arbitrary register counts, register names,
addresses, reset values, policy matrices, and more than two peripheral
completers remain unselected.

## Selection

`.658` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.658`: audit generalized APB
multi-peripheral multi-register source-shape readiness after selected
`reg0`/`reg1` timing families shipped.

The audit must decide whether the next exact owner should be:

- public contract selection for one bounded generalized source-shape family;
- a smaller source-shape/report-static prerequisite;
- an explicit deferral in favor of deeper queues, alternate overflow,
  accepted-less requester timing, multiple active APB transfers, bus
  matrices, scoreboards, or broader protection-policy families;
- explicit deferral in favor of direct backend, verification-output,
  backend-language variants, AXI, AHB, or VHDL.

## Rationale

Generalized multi-peripheral multi-register shapes are now the first named
timing residue after `.656` because the explicit selected 16/32-bit
no-policy and protected `reg0`/`reg1` two-peripheral families, plus the
selected status/control protected families, are shipped and support-accounted.

The audit is still necessary before behavior changes. Generalization would
change the public acceptance boundary from exact source families to rules
covering register cardinality, register names, local addresses, reset values,
policy matrices, and possibly peripheral counts. That is a larger semantic
contract than the previous exact-family slices and must be settled before any
parser, generator, sample, support-accounting, or HDL widening.

Deeper queues, alternate overflow, accepted-less requesters, and multiple
active APB transfers are not next because they require new requester-admission
and outstanding-transfer contracts. Bus matrices and scoreboards require new
arbitration/checking contracts. Broader protection policy families require
policy ownership and predicate-language contracts. Direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
downstream of the selected APB behavior surface.

## Audit Boundary For `.658`

`.658` must read:

- this selector;
- `.656` 32-bit protected `reg0`/`reg1`
  multi-peripheral multi-register behavior;
- `.655` 32-bit protected `reg0`/`reg1` contract;
- `.654` generalized multi-peripheral multi-register timing audit;
- `.649/.648` data16 protected `reg0`/`reg1`
  multi-peripheral multi-register behavior and contract;
- `.645/.644` data16 no-policy `reg0`/`reg1`
  multi-peripheral multi-register behavior and contract;
- `.642/.641` 32-bit no-policy `reg0`/`reg1`
  multi-peripheral multi-register behavior and contract;
- `.638/.637` 32-bit status/control protected multi-peripheral behavior and
  contract;
- `.634/.633` data16 status/control protected multi-peripheral behavior and
  contract;
- current `ApbComposition` timing guards and residue text;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

The audit must not implement behavior. Its output is a precise next leaf:
contract selection, direct implementation of one exact source-shape family
only if already defensible, source-shape/report-static prerequisite, or
explicit deferral with rationale.

## Non-Goals

`.657` and `.658` do not select or implement:

- arbitrary generalized register-shape behavior without a public contract;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate, or
  non-privileged protection policy families;
- multi-requester interconnects, bus matrices, scoreboards, or backend-owned
  APB arbitration;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector is documentation-only. It used code/doc review of `.656`, the
current `ApbComposition` timing guard and residue, support-accounting/static
surface text, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge
Map.

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
