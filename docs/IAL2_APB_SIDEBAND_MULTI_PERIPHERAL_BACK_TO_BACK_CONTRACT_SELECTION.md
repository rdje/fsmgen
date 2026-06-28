# IAL2 APB Sideband Multi-Peripheral Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.617`
- Date: `2026-06-28`
- Status: selected
- Scope: APB sideband-aware multi-peripheral back-to-back public contract only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.617` selects the public contract for the
next bounded APB sideband-aware multi-peripheral back-to-back implementation.
It reuses the `.606` timing-policy vocabulary, the `.609` propagation-only
multi-peripheral interconnect model, the `.612` sideband requester queued
`PPROT/PSTRB` behavior, and the `.615` sideband adjacent completer setup
contract.

The selected implementation owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.618`.
It shall implement the two selected public sources below and no broader APB
timing-policy family.

No parser behavior, generator behavior, samples, support-accounting entries,
generated artifacts, schedule/check JSON, semantic JSON, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector.

## Evidence Read

This selection read:

- `docs/IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md`;
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_CONTRACT_SELECTION.md`;
- `docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`;
- `ppif/apb_composition_multi_peripheral_sideband.ppif`;
- `ppif/apb_composition_multi_peripheral_status_back_to_back.ppif`;
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`;
- `perl/FSM/Support/RegressionCorpus.pm`;
- `perl/FSM/Support/LanguageSurfaceSection.pm`;
- focused APB/profile-alias/support tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

## Selected Public Sources

`.618` shall implement exactly these two public sources:

- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb`

The `.apb` profile alias must mirror the `.ppif` source and lower through
generated `.isf` review artifacts before generated `.fsm` artifacts.

## Selected Source Contract

The selected source is a sideband-aware variant of
`apb_composition_multi_peripheral_status_back_to_back` and a timing-policy
variant of `apb_composition_multi_peripheral_sideband`:

- one requester and exactly two peripheral completers;
- 32-bit `PADDR`, `PWDATA`, and `PRDATA`;
- requester request `PPROT` source `req_prot width 3`;
- requester request `PSTRB` source `req_wstrb width 4`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 4`;
- requester response fields include `accepted`, `busy`, and `status width 2`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- every peripheral completer has exactly one address-0 32-bit register;
- static non-overlapping address-map/decode stays the current two-window
  status/control shape;
- the composition itself has no top-level timing-policy clause.

The selected implementation must preserve the existing generated interconnect
role: decode the current `PSEL/PADDR`, fan out decoded `PSEL`, forward
`PENABLE`, propagate `PWRITE/PWDATA/PPROT/PSTRB`, mux selected responses, and
complete unmapped accesses only on active `PSEL && PENABLE` cycles.

## Report And Residue Contract

Selected reports shall add aggregate `back_to_back_policy` metadata using the
existing no-sideband multi-peripheral report shape, with requester,
interconnect, and every peripheral endpoint represented.

The selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed `apb_additional_back_to_back_policies_deferred` residue for
data16/protection timing variants, multi-register timing policy, deeper queues,
alternate overflow policies, accepted-less requesters, multiple active APB
transfers, multi-requester interconnects, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL.

Because this selected family propagates `PPROT/PSTRB` but does not enforce a
register-local access policy, it shall continue to report the existing
protection-policy effects residue.

## Support Accounting

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_sideband_status_back_to_back_pipeline_cli`

## Diagnostics

The implementation owner shall keep diagnostics fail-closed:

- timing propagation accepts only the selected two-peripheral 32-bit sideband
  family;
- requester timing policy must be queued, queue-depth 1, overflow reject, with
  accepted/busy/status response fields;
- every peripheral completer must use adjacent setup admission;
- requester, interconnect wiring, and every peripheral completer bus must agree
  on `PPROT width 3` and `PSTRB width 4`;
- partial sideband declarations remain rejected by existing sideband bundle
  diagnostics;
- data16/protection timing-policy variants, multi-register timing policy,
  queue depths other than 1, alternate overflow, accepted-less requesters,
  multiple active APB transfers, and unsupported peripheral counts remain
  rejected in `.618`.

## Validation Target For `.618`

The implementation owner should cover:

- syntax checks for `ApbComposition.pm`, `RegressionCorpus.pm`,
  `LanguageSurfaceSection.pm`, and focused APB/profile-alias/support tests;
- focused parser/report assertions in `t/1472-ial2-apb-composition.t`;
- `.apb` profile-alias identity/parity coverage in
  `t/1470-ial2-apb-profile-alias.t`;
- support-accounting coverage in `t/248-regression-corpus-accounting.t`;
- capability manifest coverage in `t/297-capability-manifest.t`;
- direct schedule/check/semantic JSON probes for both selected public sources;
- generated review artifact and HDL-shape probes showing queued sideband setup
  propagation through `apb_interconnect`; and
- Knowledge Map, mdBook, docs path, memory, diff, and doctrine gates.

## Deferred Work

This contract does not select data16/protection back-to-back variants,
multi-register timing policy, queue depths greater than 1, overflow policies
other than `reject`, accepted-less requester surfaces, multiple active APB
transfers, multi-requester interconnects, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, or VHDL
behavior.

## Rollback

Rollback is doc-only: revert this contract selection, its fact card, README,
ROADMAP_V2, mdBook, task tree, Memory, and generated Knowledge Map changes.
The `.615` sideband fixed-composition behavior and all existing APB, AXI, AHB,
and VHDL behavior remain unchanged.
