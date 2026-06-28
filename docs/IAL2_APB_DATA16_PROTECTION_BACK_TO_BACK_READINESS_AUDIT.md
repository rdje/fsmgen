# IAL2 APB Data16/Protection Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.620`
- Date: `2026-06-28`
- Status: readiness audited
- Scope: APB data16/protection back-to-back timing-policy readiness after
  selected 32-bit no-sideband and sideband-aware timing propagation shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.620` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.621`, public contract selection for a
bounded APB sideband-aware multi-register back-to-back timing-policy
prerequisite, before any data16/protection timing-policy behavior change.

This audit changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

The audit read:

- `.619` selector;
- `.618` sideband-aware multi-peripheral back-to-back behavior;
- `.617` sideband-aware multi-peripheral back-to-back contract selection;
- `.615` sideband completer and fixed-composition back-to-back behavior;
- `.612` sideband requester queued `PPROT/PSTRB` behavior;
- `.609` no-sideband multi-peripheral back-to-back behavior;
- `.607/.606` base APB back-to-back behavior and contract;
- `.603`, `.597`, `.594`, and `.589` APB data16/protection/sideband behavior
  records;
- APB requester, completer, and composition timing-policy guards;
- RegressionCorpus, LanguageSurfaceSection, focused APB/profile-alias/support
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

Live schedule-report probes over representative data16/protection samples show
the expected broad timing-policy residue:

```text
ppif/apb_requester_transfer_sideband_data16.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_data16.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_data16.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_protection.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_protection.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
```

The simpler 32-bit sideband multi-register family also still carries the broad
back-to-back residue:

```text
ppif/apb_completer_multi_register_sideband.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband.ppif:
  no back_to_back_policy; keeps apb_back_to_back_policy_deferred
```

## Guard Findings

Current timing-policy guards are deliberately narrow:

- `ApbRequesterTransfer` accepts selected back-to-back timing only for 32-bit
  no-sideband or selected 32-bit sideband-aware requester families.
- `ApbCompleter` accepts adjacent setup only for one address-0 register in the
  selected 32-bit no-sideband or selected 32-bit sideband-aware completer
  families.
- `ApbComposition` accepts fixed and multi-peripheral timing propagation only
  for the selected 32-bit no-sideband or selected 32-bit sideband-aware wiring
  families and rejects multi-register completer storage for timing
  propagation.

Those guards explain why a direct data16/protection behavior slice would be too
wide: every shipped data16/protection completer/composition sample uses
multi-register storage, and data16/protection additionally introduce narrower
`PSTRB`, 16-bit data, register-local denied-access semantics, and combined
report residue movement.

## Why Multi-Register Prerequisite Next

The next safest owner is the sideband-aware multi-register timing prerequisite
because it isolates the shared blocker behind data16 and protection:

- it keeps the already-shipped 32-bit sideband requester queue from `.612`;
- it keeps `PPROT width 3` and `PSTRB width 4`, avoiding data16 width changes;
- it exercises multi-register completer decode/storage without access-policy
  denied-read/write semantics;
- it can validate adjacent setup admission for multi-register completers before
  adding data16 byte-lane width changes or protection-policy effects;
- it can settle fixed and multi-peripheral report/support movement for
  multi-register timing propagation before broader data16/protection samples
  are selected.

Data16-only, protection-only, and combined data16-protection back-to-back
contracts remain important, but selecting them before the multi-register
timing-policy prerequisite would combine multiple unproven axes in one slice.

## `.621` Contract-Selection Questions

`.621` must select the exact public contract before implementation, including:

- whether the first multi-register timing-policy contract includes standalone
  completer, fixed composition, multi-peripheral composition, or a smaller
  subset;
- exact `.ppif` and `.apb` sample names;
- whether all selected completers must be sideband-aware 32-bit, use
  `PPROT width 3` and `PSTRB width 4`, and have source-order aligned
  multi-register storage;
- whether the selected requester is exactly the `.612` 32-bit sideband status
  back-to-back requester;
- fixed-composition and multi-peripheral endpoint compatibility rules;
- report/residue movement and support-accounting identities;
- diagnostics, validation gates, rollback boundaries, and downstream mdBook
  wording;
- explicit deferral for data16, protection-policy effects, combined
  data16-protection, deeper queues, alternate overflow, accepted-less
  requesters, multiple active APB transfers, direct backend,
  verification-output, backend-language variants, AXI, AHB, and VHDL.

## Deferred Work

This audit does not select data16 timing behavior, protection-policy timing
behavior, combined data16-protection timing behavior, queue depths greater than
1, overflow policies other than `reject`, accepted-less requester surfaces,
multiple active APB bus transfers, bus matrices, scoreboards, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, AHB behavior, or VHDL behavior.

## Validation

Focused validation for this audit is documentation and live-report based:

```bash
perl -MJSON::PP -e '...' \
  ppif/apb_requester_transfer_sideband_data16.ppif \
  ppif/apb_composition_multi_register_sideband_data16.ppif \
  ppif/apb_composition_multi_peripheral_sideband_data16.ppif \
  ppif/apb_composition_multi_register_sideband_protection.ppif \
  ppif/apb_composition_multi_peripheral_sideband_protection.ppif \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif

perl -MJSON::PP -e '...' \
  ppif/apb_completer_multi_register_sideband.ppif \
  ppif/apb_composition_multi_register_sideband.ppif \
  ppif/apb_composition_multi_peripheral_sideband.ppif
```

Closeout runs Knowledge Map generation/check, mdBook build, docs path, memory,
diff, and doctrine gates.
