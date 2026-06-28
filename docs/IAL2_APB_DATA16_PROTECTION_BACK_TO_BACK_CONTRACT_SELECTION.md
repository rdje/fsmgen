# IAL2 APB Data16 Protection Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.630`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  data16-protection back-to-back timing-policy behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.630` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.631` to directly implement the bounded APB
sideband-aware data16-protection back-to-back timing-policy contract for
exactly four public sources:

- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb`

No new requester-only public source is selected. The fixed-composition source
must embed the already shipped `.625` data16 sideband requester timing shape
and the selected data16-protection adjacent completer shape.

This selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read:

- `.629` post-protection-back-to-back next-slice selector;
- `.628` APB sideband-aware protection back-to-back behavior;
- `.625` APB sideband-aware data16 back-to-back behavior;
- `.603` data16 protection-policy behavior;
- `.622/.621` sideband-aware multi-register timing behavior and contract;
- `.612` sideband requester queued timing behavior;
- current data16-protection standalone, fixed-composition, and
  multi-peripheral samples and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live `.629` probes confirmed:

- data16-protection standalone, fixed, and multi-peripheral samples are
  16-bit, expose `protection_policy`, have no `back_to_back_policy`, and keep
  broad `apb_back_to_back_policy_deferred`;
- a temporary data16-protection adjacent-setup standalone completer candidate
  fails at the current selected-family timing guard.

## Selected Completer Contract

The selected standalone completer is the data16 protected two-register
extension of the `.625` data16 adjacent setup family and the `.628` protected
adjacent setup family:

- one `apb-completer apb_completer`;
- 32-bit `PADDR`;
- 16-bit `PWDATA`, `PRDATA`, and register data;
- bus `PPROT width 3`;
- bus `PSTRB width 2`;
- `wait_cycles width 4`;
- exactly two source-ordered storage registers:
  - `reg0` at address `0`, data width `16`, reset `0`,
    `(read allow)`, `(write require (privileged 1))`;
  - `reg1` at address `2`, data width `16`, reset `0`,
    `(read require (privileged 1))`,
    `(write require (privileged 1))`;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

`.631` may widen adjacent setup only to this selected protected data16
two-register shape. It must keep no-policy one-register, no-policy
multi-register, data16 no-policy, 32-bit protection, and earlier sideband
timing behavior unchanged.

## Protected Data16 Adjacent Behavior

The selected timing policy must preserve the `.603` protection and `.625`
data16 byte-lane semantics:

- `PPROT`, `PSTRB`, and `PWDATA` are sampled on every admitted setup phase,
  including an adjacent setup after the prior access response;
- allowed mapped reads return selected 16-bit register data;
- allowed mapped writes update only selected `PSTRB` byte lanes;
- `PSTRB=0` remains a successful no-byte write when the mapped write is
  allowed;
- denied reads complete with `PREADY=1`, `PSLVERR=1`, and `PRDATA=0`;
- denied writes complete with `PREADY=1`, `PSLVERR=1`, and no storage update,
  including when `PSTRB=0`;
- unmapped accesses keep unmapped-address error behavior and do not evaluate
  register-local policy;
- adjacent setup admission must not create more than one active APB transfer.

## Selected Fixed Composition Contract

The selected fixed composition combines:

- the `.625` 16-bit sideband requester timing policy:
  `(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`;
- requester response `accepted`, `busy`, and `status width 2`;
- requester `req_wdata width 16`, `req_prot width 3`, and
  `req_wstrb width 2`;
- requester `last_read_data width 16`;
- the selected protected data16 two-register adjacent setup completer above;
- one requester child and one completer child;
- 32-bit address, 16-bit data, `PPROT width 3`, and `PSTRB width 2` fixed
  wiring;
- no top-level `apb-composition` timing-policy clause.

The generated fixed composition must only propagate `PPROT/PSTRB/PWDATA` and
mux the selected protected completer response. Protection enforcement remains
owned by the completer. The top must expose requester `accepted`, `busy`,
`status`, `done`, `last_error`, and `last_read_data` outputs.

## Report And Support Movement

Selected standalone reports must add the existing endpoint `timing_policy`
shape and preserve both `width_policy` and `protection_policy` metadata.
Selected fixed-composition reports must add aggregate `back_to_back_policy`
metadata while preserving `composition.width_policy` and
`protection_policy.enforcement_owner = completer`.

Selected reports must remove broad `apb_back_to_back_policy_deferred` only for
the four selected data16-protection timing surfaces. They must retain:

- `apb_additional_back_to_back_policies_deferred` for unselected APB timing
  families;
- `apb_additional_protection_policies_deferred` for unsupported `PPROT`
  predicates, global/window/interconnect-owned policy, runtime policy, and
  broader protection-policy semantics;
- `apb_remaining_widths_deferred` for widths beyond the selected 16/32-bit
  data boundary, alternate address widths, and alternate wait-count widths;
- `apb_interconnect_multi_peripheral_decode_deferred` for unselected
  multi-peripheral timing/decode propagation on standalone/fixed surfaces.

Selected support-accounting identities:

- `intent.ppif_apb_completer_multi_register_sideband_data16_protection_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_data16_protection_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_completer_multi_register_sideband_data16_protection_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_multi_register_sideband_data16_protection_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`

## Diagnostics

`.631` must reject unsupported combined data16-protection timing shapes,
including:

- protected data16 timing without complete `PPROT/PSTRB` sidebands;
- data widths other than `16`;
- `PSTRB` widths other than `2`;
- protected storage with more or fewer than the selected two registers;
- protected storage with register addresses other than `0` and `2`;
- access-policy clauses outside the exact selected register-local policy
  shape;
- fixed compositions with missing requester `accepted/busy/status` timing
  response;
- multi-peripheral data16-protection timing propagation;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers.

## Validation Target For `.631`

The implementation owner should cover:

- syntax checks for touched APB modules/tests;
- direct schedule JSON, strict check JSON, semantic JSON, generated review
  artifact, and HDL-shape probes for all four selected public sources;
- standalone completer evidence for adjacent setup plus protected data16
  read/write allow/deny behavior;
- fixed-composition evidence for queued 16-bit `PWDATA`, `PPROT`, and 2-bit
  `PSTRB` propagation into the protected data16 completer;
- malformed combined timing diagnostics for wrong address, wrong policy,
  wrong widths, and multi-peripheral attempts;
- focused APB profile-alias, completer, composition, support-accounting, and
  capability-manifest tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Work

This selection does not include multi-peripheral data16-protection timing,
broader multi-peripheral multi-register timing propagation, queue depths
greater than `1`, overflow policies other than `reject`, accepted-less
requesters, multiple active APB transfers, additional `PPROT` predicates,
global/window/interconnect-owned protection policies, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, or VHDL
behavior.

## Rollback

Rollback of the future `.631` implementation removes only the four selected
public samples, selected data16-protection timing-policy guard widening,
support-accounting entries, focused tests, behavior docs, Knowledge Map fact
card, README, ROADMAP_V2, mdBook, task tree, Memory, and generated Knowledge
Map updates. Existing 32-bit timing, data16 no-policy timing, protection-only
timing, APB data16/protection behavior without timing, AXI, AHB, and VHDL
behavior remain owned by earlier or future slices.
