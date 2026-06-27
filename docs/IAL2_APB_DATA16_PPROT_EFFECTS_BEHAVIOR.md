# IAL2 APB Data16 PPROT Access-Policy Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.603`

Date: 2026-06-27

## Outcome

FSMGen ships the selected `sideband_data16_protection` APB contract. It extends
the existing register-local `PPROT[0]` access-policy behavior to the
sideband-aware 16-bit APB data path.

New support-accounted samples:

```text
ppif/apb_completer_multi_register_sideband_data16_protection.ppif
ppif/apb_completer_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_register_sideband_data16_protection.ppif
ppif/apb_composition_multi_register_sideband_data16_protection.apb
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb
```

The no-policy data16 samples remain unchanged.

## Behavior

Data16 protection keeps the data16 width contract:

- 16-bit `PWDATA`, `PRDATA`, and storage registers;
- 2-bit `PSTRB` and two little-endian byte lanes;
- 2-byte-aligned register addresses and address-map windows;
- 32-bit `PADDR`, 4-bit wait counts, and 3-bit `PPROT`.

The policy syntax is the same register-local shape as the 32-bit protection
contract:

```lisp
(access-policy
  (read require (privileged 1))
  (write require (privileged 1)))
```

`privileged` means sampled `PPROT[0] == VALUE`. The completer samples `PPROT`
and `PSTRB` during APB setup. Allowed mapped writes update only the selected
16-bit byte lanes. Denied mapped reads complete with `PREADY=1`, `PSLVERR=1`,
and zero read data. Denied mapped writes complete with `PSLVERR=1` and do not
update storage, including when `PSTRB=0`.

Fixed composition only propagates `PPROT/PSTRB` and muxes the selected
completer response. Multi-peripheral composition keeps the generated
interconnect propagation-only; endpoint peripheral completers enforce the
policy.

## Reports And Residue

The new support-accounting identities are:

```text
intent.ppif_apb_completer_multi_register_sideband_data16_protection
intent.apb_profile_alias_completer_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_register_sideband_data16_protection
intent.apb_profile_alias_composition_multi_register_sideband_data16_protection
intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection
intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection
```

Reports keep `width_policy.selected_contract = sideband_data16`, add
`protection_policy`, remove `apb_protection_policy_effects_deferred`, and keep
the future work explicit through `apb_additional_protection_policies_deferred`,
`apb_remaining_widths_deferred`, and `apb_back_to_back_policy_deferred`.

## Non-Goals

This slice does not add APB data widths beyond the selected 16/32-bit boundary,
address widths beyond 32, wait-count widths beyond 4, additional `PPROT`
predicates, global/window/interconnect-owned policies, runtime-programmed
policies, back-to-back transfer admission, direct IAL2-to-IAL0 lowering,
direct backend lowering, verification-output generation, backend-language
variants, AXI behavior, AHB behavior, or VHDL behavior.

## Validation

Focused validation for `.603` covers parser/static diagnostics, schedule JSON,
check JSON, semantic JSON, generated `.isf`/`.fsm` review artifacts, HDL shape,
profile-alias parity, support accounting, and capability-manifest language
surface sync. The RAM-guarded bundled `prove` invocation stopped before launch
on a high host-memory baseline, so the same focused files were run one at a
time:

```bash
prove -Iperl t/1470-ial2-apb-profile-alias.t \
  t/1471-ial2-apb-completer.t \
  t/1472-ial2-apb-composition.t \
  t/248-regression-corpus-accounting.t \
  t/297-capability-manifest.t
```
