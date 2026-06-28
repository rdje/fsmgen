# IAL2 APB Data16 Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.624`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the bounded APB sideband-aware
  data16 back-to-back timing-policy family

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.624` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.625` to directly implement the bounded APB
sideband-aware data16 back-to-back timing-policy contract for exactly six
public sources:

- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb`

No additional prerequisite selector is needed before `.625`: the remaining
work is a bounded guard widening from the selected 32-bit sideband timing
families to the selected 16-bit sideband data path and two-register data16
shape.

This selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

The selector read:

- `.623` post-sideband-multi-register selector;
- `.622` sideband-aware multi-register back-to-back behavior;
- `.621` sideband-aware multi-register back-to-back contract selection;
- `.620` APB data16/protection back-to-back readiness audit;
- `.618`, `.615`, `.612`, `.607`, and `.606` APB timing behavior and contract
  records;
- `.594` APB data16 behavior and `.603/.597` APB protection behavior;
- current APB data16 requester, completer, fixed-composition, and
  multi-peripheral samples;
- current APB requester, completer, fixed-composition, and multi-peripheral
  timing-policy guards;
- RegressionCorpus, LanguageSurfaceSection, focused APB/profile-alias/support
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

Live report probes confirmed the selected data16 no-policy sources already
carry the intended width surface but still retain broad back-to-back residue:

```text
ppif/apb_requester_transfer_sideband_data16.ppif:
  data_width=16; strobe=2; no timing metadata; keeps apb_back_to_back_policy_deferred
ppif/apb_completer_multi_register_sideband_data16.ppif:
  data_width=16; strobe=2; no timing metadata; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_data16.ppif:
  data_width=16; strobe=2; no aggregate timing metadata; keeps apb_back_to_back_policy_deferred
```

The 32-bit timing counterparts already show the report shape `.625` should
mirror with data16 widths:

```text
ppif/apb_requester_transfer_sideband_status_back_to_back.ppif:
  data_width=32; strobe=4; endpoint timing metadata; accepted=accepted
ppif/apb_completer_multi_register_sideband_back_to_back.ppif:
  data_width=32; strobe=4; endpoint timing metadata
ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif:
  data_width=32; strobe=4; aggregate back_to_back_policy metadata
```

## Selected Requester Contract

The selected requester is the data16 sideband status variant of the `.612`
queued sideband requester:

- one `apb-requester apb_requester`;
- 32-bit `PADDR` and request address;
- 16-bit request write data, bus `PWDATA`, bus `PRDATA`, and response read
  data;
- request `(protection req_prot width 3)` and bus `PPROT width 3`;
- request `(write-strobe req_wstrb width 2)` and bus `PSTRB width 2`;
- response fields `accepted`, `busy`, `status width 2`, `done`,
  `last_read_data width 16`, and `last_error`;
- transfer `(timing-policy (back-to-back queued) (queue-depth 1)
  (overflow reject))`;
- unchanged APB one-active-transfer plus one queued next-transfer model.

Generated requester behavior must sample all request payload fields when
`accepted` pulses. The queued slot must store 16-bit `queued_wdata`, 3-bit
`queued_prot`, and 2-bit `queued_wstrb`. Relaunch of a queued write drives
`PSTRB` from `queued_wstrb` masked by `(concat queued_write queued_write)`.
Reads drive `PSTRB=0`. Queue depth, overflow, `busy`, `done`, `status`, and
reset semantics remain the `.607/.612` semantics.

## Selected Completer Contract

The selected standalone completer is the data16 no-policy two-register
extension of the `.622` adjacent setup family:

- one `apb-completer apb_completer`;
- 32-bit `PADDR`;
- 16-bit `PWDATA`, `PRDATA`, and register data;
- bus `PPROT width 3`;
- bus `PSTRB width 2`;
- `wait_cycles width 4`;
- exactly two source-ordered storage registers:
  - `reg0` at address `0`, data width `16`, reset `0`;
  - `reg1` at address `2`, data width `16`, reset `0`;
- no register-local `access-policy` clauses in this data16 timing owner;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

Generated completer behavior must preserve the `.594` data16 byte-lane
semantics: `PSTRB[0]` updates bits `[7:0]`, `PSTRB[1]` updates bits `[15:8]`,
and `PSTRB=0` is a successful no-byte write for mapped allowed writes. The
selected adjacent setup policy admits a setup cycle that immediately follows
the prior access response. Unmapped-address, wait-cycle, read, and `PSLVERR`
behavior remain unchanged.

## Selected Fixed-Composition Contract

The selected fixed composition combines:

- the selected data16 sideband status requester timing policy above;
- the selected data16 sideband multi-register adjacent setup completer above;
- one requester child and one completer child;
- sideband-aware fixed wiring with 32-bit address, 16-bit data,
  `PPROT width 3`, and `PSTRB width 2`;
- no top-level `apb-composition` timing-policy clause.

The fixed composition derives aggregate `back_to_back_policy` metadata from
compatible endpoint timing policies. It exposes the requester `accepted`
output at the top level, propagates queued requester `PPROT/PSTRB/PWDATA`
through the 16-bit bus, and lets the completer sample the queued sideband and
data payload on the adjacent setup cycle.

`.625` should implement requester, standalone completer, and fixed composition
together because the selected data16 fixed composition cannot be validated
without both endpoint timing policies, while each endpoint remains small enough
for the same bounded implementation owner.

## Report And Support Movement

Selected requester and completer reports must add the existing endpoint
`timing_policy` shapes. Selected fixed-composition reports must add aggregate
`back_to_back_policy` metadata using the existing fixed-composition report
shape.

Selected reports must remove broad `apb_back_to_back_policy_deferred` residue
only for the six selected data16 timing surfaces. They must retain:

- `apb_additional_back_to_back_policies_deferred` for unselected APB timing
  families;
- `apb_remaining_widths_deferred` for data widths beyond the selected
  sideband-aware 16/32-bit boundary, alternate address widths, and alternate
  wait-count widths;
- `apb_protection_policy_effects_deferred` because this owner has no
  register-local access-policy clauses.

Selected support-accounting identities:

- `intent.ppif_apb_requester_transfer_sideband_data16_status_back_to_back`
- `intent.apb_profile_alias_requester_transfer_sideband_data16_status_back_to_back`
- `intent.ppif_apb_completer_multi_register_sideband_data16_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_data16_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_data16_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_data16_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_requester_transfer_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_requester_transfer_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_ppif_apb_completer_multi_register_sideband_data16_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_multi_register_sideband_data16_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_multi_register_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_register_sideband_data16_status_back_to_back_pipeline_cli`

## Diagnostics

The implementation owner shall keep diagnostics fail-closed:

- requester timing requires the selected queued depth-1 overflow-reject policy
  and `accepted/busy/status width 2`;
- requester timing accepts only the selected 32-bit no-sideband, selected
  32-bit sideband-aware, and selected sideband-aware data16 requester families;
- data16 requester timing requires complete `PPROT/PSTRB` sideband bindings
  and data-derived strobe width `2`;
- completer adjacent setup accepts only the previous selected 32-bit families
  plus the selected data16 sideband-aware two-register no-policy shape;
- data16 completer timing requires `reg0` at address `0`, `reg1` at address
  `2`, 16-bit register data, reset `0`, `PSTRB width 2`, and no
  `access-policy`;
- fixed-composition timing requires compatible selected requester/completer
  endpoint policies and matching 16-bit sideband-aware bus wiring;
- protection-policy timing, combined data16-protection timing,
  multi-peripheral multi-register timing, deeper queues, alternate overflow,
  accepted-less requesters, multiple active APB transfers, and unsupported
  topology shapes remain rejected or deferred.

## Validation Target For `.625`

The implementation owner should cover:

- syntax checks for `ApbRequesterTransfer.pm`, `ApbCompleter.pm`,
  `ApbComposition.pm`, `RegressionCorpus.pm`, `LanguageSurfaceSection.pm`,
  and focused APB/profile-alias/support tests;
- direct schedule JSON, check JSON, semantic JSON, generated review artifact,
  and HDL-shape probes for all six selected public sources;
- requester generated `.fsm` evidence for 16-bit `queued_wdata`, 3-bit
  `queued_prot`, 2-bit `queued_wstrb`, and two-lane queued `PSTRB` masking;
- completer generated `.fsm` evidence for two 16-bit registers at addresses
  `0` and `2`, two byte-lane write masks, and adjacent setup metadata;
- fixed-composition report evidence for aggregate `back_to_back_policy` plus
  data16 width-policy preservation;
- `.ppif`/`.apb` profile-alias parity;
- support-accounting and capability-manifest updates;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Work

This contract does not select protection-only timing behavior, combined
data16-protection timing behavior, multi-peripheral multi-register timing
propagation, queue depths greater than `1`, overflow policies other than
`reject`, accepted-less requester surfaces, multiple active APB bus transfers,
multi-requester interconnects, bus matrices, scoreboards, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, AHB behavior, or VHDL behavior.

## Validation

Selector validation used documentation/code review plus live report probes:

```bash
perl -MJSON::PP -we '...' \
  ppif/apb_requester_transfer_sideband_data16.ppif \
  ppif/apb_completer_multi_register_sideband_data16.ppif \
  ppif/apb_composition_multi_register_sideband_data16.ppif \
  ppif/apb_requester_transfer_sideband_status_back_to_back.ppif \
  ppif/apb_completer_multi_register_sideband_back_to_back.ppif \
  ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif
```

Closeout also runs Knowledge Map generation/check, mdBook build, docs path,
memory, diff, and doctrine gates.

## Rollback

Rollback is doc-only: revert this selector, its fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map changes. The `.622`
sideband-aware multi-register timing behavior, `.594` data16 behavior, and all
existing APB, AXI, AHB, and VHDL behavior remain unchanged.
