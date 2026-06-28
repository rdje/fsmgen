# IAL2 Post-APB Sideband Multi-Peripheral Back-To-Back Next Slice Selection

Date: 2026-06-28

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.619`

## Decision

`.619` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.620`, an APB
data16/protection back-to-back timing-policy readiness audit, as the next
APB/IAL2 feature-completeness owner after the selected 32-bit sideband-aware
multi-peripheral back-to-back family shipped.

This is a no-behavior selector. It does not change APB source acceptance,
parser behavior, generator behavior, sample files, support-accounting catalog
entries, validation behavior, generated artifacts, schedule/check/semantic JSON
behavior, HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

The selector read:

- `.618` APB sideband-aware multi-peripheral back-to-back behavior;
- `.617` sideband multi-peripheral back-to-back contract selection;
- `.615` sideband completer and fixed-composition back-to-back behavior;
- `.612` sideband requester queued `PPROT/PSTRB` behavior;
- `.609` no-sideband multi-peripheral back-to-back behavior;
- `.607/.606` base APB back-to-back behavior and contract;
- `.603`, `.597`, `.594`, and `.589` APB data16/protection/sideband behavior
  records;
- APB requester, completer, and composition timing-policy guards;
- current report residue for representative data16 and protection APB samples;
- RegressionCorpus, LanguageSurfaceSection, focused APB/profile-alias/support
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

Live schedule-report probes confirmed the remaining broad back-to-back residue
is still present on data16/protection families:

- `ppif/apb_requester_transfer_sideband_data16.ppif` reports no
  `back_to_back_policy` and keeps `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_register_sideband_data16.ppif` reports no
  `back_to_back_policy` and keeps `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_peripheral_sideband_data16.ppif` reports no
  `back_to_back_policy` and keeps `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_register_sideband_protection.ppif` reports no
  `back_to_back_policy` and keeps `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_peripheral_sideband_protection.ppif` reports no
  `back_to_back_policy` and keeps `apb_back_to_back_policy_deferred`.
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif`
  reports no `back_to_back_policy` and keeps
  `apb_back_to_back_policy_deferred`.

Current code guards are intentionally narrow:

- requester back-to-back timing accepts only 32-bit no-sideband or selected
  32-bit sideband-aware requester families;
- completer adjacent setup accepts only one-register 32-bit no-sideband or
  selected 32-bit sideband-aware completer families;
- fixed and multi-peripheral composition propagation accepts only the shipped
  32-bit no-sideband or selected 32-bit sideband-aware wiring families and
  rejects multi-register completer storage for timing propagation.

## Why Data16/Protection Readiness Next

The 32-bit timing-policy ladder is now shipped for requester, completer, fixed
composition, no-sideband multi-peripheral composition, sideband requester,
sideband completer, sideband fixed composition, and selected sideband
multi-peripheral composition. The remaining public APB surfaces with broad
`apb_back_to_back_policy_deferred` are now concentrated in the data16,
protection, and data16-protection families.

Those families should not jump directly to behavior because they combine
several still-unsettled boundaries:

- data16 requester queue payload width and `PSTRB` width 2 capture/relaunch;
- adjacent completer setup for 16-bit data and two-byte lane writes;
- protection-policy interaction with denied accesses, zero-strobe writes, and
  queued sideband `PPROT`;
- multi-register storage, where the current adjacent-setup guard still rejects
  timing-policy propagation;
- fixed and multi-peripheral composition report movement for data16,
  protection, and combined data16-protection shapes.

Queue depths beyond 1, overflow policies beyond `reject`, multiple active APB
transfers, direct backend lowering, verification-output generation, and
backend-language variants remain later owners because they would widen already
shipped timing semantics before the existing data16/protection APB public
surfaces have a selected readiness boundary.

## `.620` Readiness Questions

`.620` must decide whether the next exact owner should be:

- a data16-only back-to-back contract;
- a protection-only back-to-back contract;
- a combined data16-protection contract;
- a multi-register adjacent-setup prerequisite;
- a requester-only or completer-only prerequisite;
- a report/static cleanup prerequisite;
- or explicit deferral behind a better-supported owner.

The audit must record:

- exact source/sample candidates and whether they should be fixed composition,
  multi-peripheral composition, standalone requester/completer, or split;
- requester queue payload fields for `PSTRB width 2`, `PPROT`, read data, and
  response status;
- adjacent setup behavior for data16 byte-lane writes and protection denied
  reads/writes;
- whether multi-register completer timing policy can be selected directly or
  needs a prerequisite;
- composition/interconnect propagation and response mux expectations;
- report, unsupported-residue, support-accounting, diagnostics, validation, and
  rollback boundaries;
- direct-backend, verification-output, backend-language, AXI, AHB, and VHDL
  deferrals.

## Deferred Work

This selector does not select queue depths greater than 1, overflow policies
other than `reject`, accepted-less requester surfaces, multiple active APB bus
transfers, bus matrices, scoreboards, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior.
