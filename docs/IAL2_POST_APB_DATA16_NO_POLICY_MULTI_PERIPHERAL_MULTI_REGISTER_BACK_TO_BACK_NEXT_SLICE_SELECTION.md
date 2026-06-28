# IAL2 Post APB Data16 No-Policy Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.646`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing residue owner after selected data16
  no-policy multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.646` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.647`, a readiness audit for APB
data16-protection generalization.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

The APB back-to-back timing frontier now has these selected behaviors shipped:

- fixed 32-bit no-sideband requester/completer/composition timing;
- selected 32-bit sideband requester/completer/fixed-composition timing;
- selected 32-bit sideband no-policy multi-register fixed-composition timing;
- selected 32-bit sideband protection multi-register fixed-composition timing;
- selected sideband data16 no-policy requester/completer/fixed-composition
  timing;
- selected sideband data16-protection standalone completer and
  fixed-composition timing;
- selected no-sideband two-peripheral multi-peripheral timing;
- selected 32-bit sideband two-peripheral one-register multi-peripheral
  timing;
- selected sideband data16-protection status/control two-peripheral timing;
- selected 32-bit sideband protection status/control two-peripheral timing;
- selected 32-bit sideband no-policy reg0/reg1 two-peripheral timing;
- selected sideband data16 no-policy reg0/reg1 two-peripheral timing.

The current public data16-protection sources define two relevant boundaries:

- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
  ships fixed-composition protected data16 timing with two protected
  registers, 16-bit data, `PPROT width 3`, and `PSTRB width 2`.
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
  ships selected multi-peripheral protected data16 timing for the
  status/control topology, 2-byte-aligned windows, and peripheral-owned
  register-local `PPROT[0]` enforcement.

No explicit public
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
or matching `.apb` alias exists yet. The shipped `.634` protected data16
multi-peripheral family already has two protected registers per peripheral,
but it is selected as the status/control protected family rather than a
generalized multi-peripheral multi-register data16-protection contract.

## Selection

`.647` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.647`: audit APB data16-protection
generalization readiness.

The audit must decide whether the next exact owner is:

- public contract selection for an explicit bounded data16-protection
  multi-peripheral multi-register source family;
- direct implementation of one already-selected exact family;
- a smaller source-shape/report-static prerequisite;
- explicit deferral because `.634` is the current selected boundary and the
  next behavior should move to generalized register shapes or another residue.

## Rationale

Data16-protection generalization is now the smallest coherent APB timing
residue to audit before another behavior change.

The no-policy multi-peripheral multi-register axis is covered for both 32-bit
and data16 selected families after `.642` and `.645`. The protected
multi-peripheral axis is covered for selected 32-bit and selected data16
status/control families after `.638` and `.634`. The remaining ambiguity is
the overlap between the selected data16-protection status/control family and a
possible explicit data16-protection multi-peripheral multi-register public
contract.

The current residue text names data16-protection generalization before
generalized multi-peripheral multi-register timing. That order is appropriate
because data16-protection can likely reuse shipped requester queueing,
adjacent protected data16 completers, and selected two-peripheral interconnect
propagation, while generalized register counts/names/policies need broader
shape and policy contracts.

Deeper queues, alternate overflow policies, accepted-less requesters, multiple
active APB transfers, bus matrices, and scoreboards are not next because they
need new requester-admission, APB outstanding-model, arbitration, or checking
contracts before composition propagation can be judged safe. Direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
and VHDL remain downstream of the selected APB behavior surface.

## Audit Boundary For `.647`

`.647` must read:

- this selector;
- `.645` data16 no-policy multi-peripheral multi-register behavior;
- `.644` data16 no-policy multi-peripheral multi-register contract;
- `.643` data16 no-policy selector;
- `.642/.641/.640` no-policy multi-peripheral multi-register records;
- `.638` protected multi-peripheral behavior;
- `.634/.633` data16-protection multi-peripheral records;
- `.631/.630/.629` data16-protection fixed-composition records;
- `.625` data16 no-policy fixed-composition behavior;
- current fixed and multi-peripheral data16-protection `.ppif`/`.apb` sources
  and reports;
- `ApbRequesterTransfer`, `ApbCompleter`, and `ApbComposition` timing guards
  and residue text;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused
  APB/profile-alias/support tests, README, ROADMAP_V2, mdBook, task tree,
  Memory, Knowledge Map, and relevant decisions.

The audit must not implement behavior. Its output is a precise next leaf:
direct implementation of one exact public-source family, public contract
selection, source-shape/report-static prerequisite, or explicit deferral with
rationale.

## Non-Goals

`.646` and `.647` do not select or implement:

- generalized register counts, names, addresses, or policy matrices;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned protection policy;
- multi-requester interconnects, bus matrices, or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector is documentation-only. It used code/doc review plus live
schedule-report probes for representative shipped surfaces:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif
```

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
