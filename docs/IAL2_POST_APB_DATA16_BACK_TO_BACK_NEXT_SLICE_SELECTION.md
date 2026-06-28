# IAL2 Post APB Data16 Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.626`
- Date: `2026-06-28`
- Status: selected
- Scope: no-behavior next-owner selection after selected APB sideband-aware
  data16 back-to-back behavior shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.626` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.627`, public contract selection for a
bounded APB sideband-aware protection back-to-back timing-policy family, before
any behavior change.

This selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read:

- `.625` APB sideband-aware data16 back-to-back behavior;
- `.624` APB data16 back-to-back contract selection;
- `.620` APB data16/protection back-to-back readiness audit;
- `.622/.621` sideband-aware multi-register timing behavior and contract;
- `.618/.615/.612/.607/.606` APB timing behavior and contract records;
- `.603/.597` APB data16 and 32-bit `PPROT` access-policy behavior;
- `.594/.589` APB data16 and sideband/strobe behavior;
- current APB protection, data16-protection, and multi-peripheral reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live schedule-report probes after `.625` confirm protection and
data16-protection samples still keep broad timing-policy residue:

```text
ppif/apb_completer_multi_register_sideband_protection.ppif:
  data_width=32; strobe_width=4; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_protection.ppif:
  data_width=32; strobe_width=4; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_protection.ppif:
  data_width=32; strobe_width=4; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_completer_multi_register_sideband_data16_protection.ppif:
  data_width=16; strobe_width=2; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_data16_protection.ppif:
  data_width=16; strobe_width=2; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif:
  data_width=16; strobe_width=2; protection_policy present;
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
```

A temporary protected standalone completer candidate with
`(timing-policy (setup-admission adjacent))` fails at the current
`ApbCompleter` guard:

```text
selected setup-admission adjacent policy supports only the selected 32-bit
no-sideband one-register, selected 32-bit sideband-aware one-register,
selected 32-bit sideband-aware two-register no-policy, or selected
sideband-aware data16 two-register no-policy completer families in this slice
```

That failure is the expected boundary: `.625` deliberately added data16
no-policy timing, not register-local access-policy timing.

## Why Protection-Only Next

Protection-only timing is the next narrowest axis:

- selected 32-bit sideband requester queue behavior already ships in `.612`;
- selected sideband-aware two-register no-policy adjacent setup already ships
  in `.622`;
- selected data16 no-policy timing now ships in `.625`;
- 32-bit protection keeps `PSTRB width 4`, avoiding data16 byte-lane width
  changes while the access-policy timing contract is settled;
- protection-only timing isolates denied-read and denied-write semantics from
  combined data16-protection timing;
- multi-peripheral multi-register timing propagation remains a separate axis
  and should not be pulled into the first protected timing owner by accident.

Data16-protection timing remains important, but it should build on a settled
32-bit protected timing contract. Multi-peripheral multi-register timing,
deeper queues, alternate overflow, accepted-less requesters, and multiple
active APB transfers remain broader timing-policy work.

## `.627` Contract-Selection Questions

`.627` must select the exact public contract before implementation, including:

- whether the first protection timing family includes standalone completer,
  fixed composition, or a smaller subset;
- exact `.ppif` and `.apb` sample names;
- endpoint policy requirements for the existing 32-bit sideband requester
  queue and protected multi-register completer storage;
- whether selected protected timing requires exactly register-local
  `access-policy` clauses already shipped by `.597`;
- adjacent setup behavior for allowed writes, zero-strobe allowed writes,
  denied writes, allowed reads, denied reads, and unmapped accesses;
- whether the fixed composition only propagates `PPROT/PSTRB` and muxes the
  protected completer response, preserving endpoint enforcement ownership;
- report/residue movement for `timing_policy`, aggregate
  `back_to_back_policy`, `protection_policy`, future timing residue, and
  additional-protection residue;
- diagnostics for malformed protected timing shapes;
- focused parser/generator/profile-alias/support/capability tests;
- direct schedule/check/semantic JSON and temporary HDL-shape probes;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, validation,
  and rollback boundaries.

`.627` must keep combined data16-protection timing, multi-peripheral
multi-register timing propagation, deeper queues, alternate overflow policies,
accepted-less requesters, multiple active APB transfers, direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
and VHDL behavior deferred unless it explicitly selects a smaller prerequisite
instead of implementation.

## Validation

Focused validation for this selector is documentation and live-report based:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_completer_multi_register_sideband_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_completer_multi_register_sideband_data16_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_data16_protection.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
```

The selector also probes a temporary protected adjacent-setup candidate to
confirm current guard rejection, then runs Knowledge Map generation/check,
mdBook build, docs path, memory, diff, and doctrine gates.

## Rollback

Rollback is doc-only: remove this selector, its Knowledge Map fact card,
README, ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map
updates. `.625` APB data16 back-to-back behavior and all earlier APB
sideband/data16/protection timing behavior remain intact.
