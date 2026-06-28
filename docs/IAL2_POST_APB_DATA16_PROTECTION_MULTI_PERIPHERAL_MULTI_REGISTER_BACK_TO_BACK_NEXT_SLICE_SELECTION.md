# IAL2 Post APB Data16 Protection Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.650`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing/protection residue owner after selected
  data16-protection multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.650` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.651`, a readiness audit for APB
status/control protected-storage generalization.

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
  two-register two-peripheral timing.

The most recent `.649` behavior ships exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb`

That selected family uses requester `accepted/busy/status` depth-1 queued
timing, 16-bit APB/register data, `PPROT width 3`, `PSTRB width 2`,
status/control windows at bases `0` and `258`, adjacent setup on both
peripherals, and protected `reg0`/`reg1` storage in both peripherals.

The live narrowed `apb_additional_back_to_back_policies_deferred` residue now
names the next closer APB protected-storage gap before generalized register
shapes: status/control protected storage generalization beyond the selected
family.

## Selection

`.651` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.651`: audit APB status/control
protected-storage generalization readiness.

The audit must decide whether the next exact owner should be:

- public contract selection for a bounded status/control protected-storage
  generalization;
- direct implementation of one already-selected status/control protected
  shape;
- a smaller report/static/source-shape prerequisite;
- explicit deferral in favor of generalized multi-peripheral multi-register
  shapes or another APB timing/protection residue.

## Rationale

Status/control protected-storage generalization is narrower than generalized
multi-peripheral multi-register behavior. The shipped status/control
families prove the two-peripheral decode/window model and peripheral-owned
protection enforcement for selected 32-bit and 16-bit data16 protected
topologies. The shipped `.649` reg0/reg1 family proves the selected
data16-protection multi-register timing guard and report/support-accounting
path for explicit `reg0`/`reg1` storage.

What remains is not yet a generalized register-shape contract. It is the
smaller question of whether status/control protected storage should be
broadened beyond the already selected `.638`, `.634`, and `.649` families,
and if so with which exact public source names, register names, policy matrix,
window requirements, diagnostics, report movement, and validation gates.

Queue depths other than `1`, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, bus matrices, and
scoreboards are not next because they require new requester-admission,
outstanding-transfer, arbitration, or checking contracts. Direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
and VHDL remain downstream of the selected APB behavior surface.

## Audit Boundary For `.651`

`.651` must read:

- this selector;
- `.649` data16-protection reg0/reg1 multi-peripheral multi-register behavior;
- `.648` data16-protection multi-peripheral multi-register contract;
- `.647` data16-protection readiness audit;
- `.645` data16 no-policy multi-peripheral multi-register behavior;
- `.642` 32-bit no-policy multi-peripheral multi-register behavior;
- `.638` 32-bit protection status/control multi-peripheral behavior;
- `.634` data16-protection status/control multi-peripheral behavior;
- `.631` data16-protection fixed-composition behavior;
- current `ApbComposition` timing guards and residue text;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB tests, README,
  ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

The audit must not implement behavior. Its output is a precise next leaf:
contract selection, direct implementation of one exact public-source family,
source-shape/report-static prerequisite, or explicit deferral with rationale.

## Non-Goals

`.650` and `.651` do not select or implement:

- generalized register counts, names, addresses, or policy matrices;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned protection policy;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector is documentation-only. It used code/doc review of the shipped
`.638`, `.634`, `.649`, and current `ApbComposition` residue surfaces.

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
