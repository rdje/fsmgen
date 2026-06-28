# IAL2 APB Sideband Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.621`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the bounded APB sideband-aware
  multi-register back-to-back timing-policy prerequisite

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.621` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.622` to implement exactly four public
sources:

- `ppif/apb_completer_multi_register_sideband_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`

The selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

The selector read:

- `.620` data16/protection back-to-back readiness audit;
- `.619` post-sideband-multi-peripheral selector;
- `.618` sideband-aware multi-peripheral back-to-back behavior;
- `.615` sideband completer and fixed-composition back-to-back behavior;
- `.612` sideband requester queued `PPROT/PSTRB` behavior;
- `.609` no-sideband multi-peripheral back-to-back behavior;
- `.607/.606` base APB back-to-back behavior and contract;
- `.589` sideband/strobe behavior and `.581` multi-register behavior;
- current APB sideband multi-register samples and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live probes confirmed that the existing sideband-aware multi-register fixed
family still reports no aggregate `back_to_back_policy` and keeps broad
`apb_back_to_back_policy_deferred`:

- `ppif/apb_completer_multi_register_sideband.ppif`;
- `ppif/apb_composition_multi_register_sideband.ppif`.

## Selected Completer Contract

The selected completer is the sideband-aware 32-bit two-register extension of
the `.615` adjacent setup completer family:

- one `apb-completer apb_completer`;
- 32-bit `PADDR`, `PWDATA`, `PRDATA`, and register data;
- bus `PPROT width 3`;
- bus `PSTRB width 4`;
- `wait_cycles width 4`;
- exactly two source-order storage registers:
  - `reg0` at address `0`, data width `32`, reset `0`;
  - `reg1` at address `4`, data width `32`, reset `0`;
- no `access-policy` clauses in this first multi-register timing prerequisite;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

The selected implementation must keep one-register no-sideband and
one-register sideband behavior unchanged. It may widen adjacent setup only to
this selected sideband-aware 32-bit multi-register, no-policy completer family.

## Selected Fixed Composition Contract

The selected fixed composition combines:

- the `.612` sideband requester timing policy:
  `(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`;
- requester response `accepted`, `busy`, and `status width 2`;
- the selected sideband-aware multi-register adjacent setup completer above;
- one requester child and one completer child;
- 32-bit sideband-aware fixed wiring with `PPROT width 3` and `PSTRB width 4`.

The composition derives aggregate `back_to_back_policy` metadata from
compatible endpoint policies. It exposes the requester `accepted` output at the
top level and propagates queued requester `PPROT/PSTRB` into the selected
multi-register completer.

The selected implementation may widen fixed-composition timing propagation only
for this sideband-aware 32-bit requester/completer/wiring family with the
selected two-register completer. Multi-peripheral multi-register timing
propagation remains deferred.

## Report And Support Movement

Selected reports must remove broad `apb_back_to_back_policy_deferred` residue
from the selected standalone completer and fixed-composition report surfaces.
They must retain narrowed `apb_additional_back_to_back_policies_deferred`
residue for unselected APB timing-policy families, including
multi-peripheral multi-register propagation, data16/protection variants, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_completer_multi_register_sideband_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_status_back_to_back`

## Diagnostics And Validation Boundary

`.622` must reject:

- missing or incompatible endpoint timing policies;
- data16 timing variants;
- protection-policy timing variants;
- multi-peripheral multi-register timing propagation;
- completers without exactly the selected sideband-aware 32-bit two-register
  no-policy shape;
- queue depths other than 1;
- overflow policies other than `reject`.

Focused validation must cover:

- syntax checks for touched APB modules/tests;
- schedule JSON, check JSON, semantic JSON, temporary-directory generated
  review artifacts, and HDL generation for the four selected public sources;
- focused APB completer, composition, profile-alias, support-accounting, and
  capability-manifest tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Work

This selection does not include multi-peripheral multi-register timing
propagation, data16 timing behavior, protection timing behavior, combined
data16-protection timing behavior, queue depths greater than 1, overflow
policies other than `reject`, accepted-less requester surfaces, multiple active
APB bus transfers, bus matrices, scoreboards, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, AHB
behavior, or VHDL behavior.

## Rollback

Rollback of the future `.622` implementation removes only the four selected
public samples, the selected multi-register sideband timing-policy guard
widening, support-accounting entries, focused tests, behavior docs, Knowledge
Map fact card, README, ROADMAP_V2, mdBook, task tree, Memory, and generated
Knowledge Map updates. Existing one-register back-to-back behavior, sideband
requester/completer/fixed behavior, sideband multi-peripheral behavior,
multi-register decode behavior, data16/protection behavior, AXI, AHB, and VHDL
remain owned by earlier or future slices.
