# IAL2 Post APB Protection Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.629`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing residue owner after selected
  protection timing behavior shipped

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.629` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.630`, public contract selection for a
bounded APB sideband-aware data16-protection back-to-back timing-policy
family, before any further behavior change.

This selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read:

- `.628` APB sideband-aware protection back-to-back behavior;
- `.627` APB sideband-aware protection back-to-back contract selection;
- `.625` APB sideband-aware data16 back-to-back behavior;
- `.620` APB data16/protection back-to-back readiness audit;
- `.622/.621` sideband-aware multi-register timing behavior and contract;
- `.612/.607` sideband and base APB back-to-back timing behavior;
- `.603/.597` data16 and 32-bit protection-policy behavior;
- current data16-protection and multi-peripheral data16-protection APB
  samples and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live schedule-report probes confirmed:

- `ppif/apb_completer_multi_register_sideband_data16_protection.ppif` and
  `.apb` are 16-bit, expose `protection_policy`, have no
  `back_to_back_policy`, and retain broad `apb_back_to_back_policy_deferred`;
- `ppif/apb_composition_multi_register_sideband_data16_protection.ppif` and
  `.apb` are 16-bit, expose `protection_policy`, have no aggregate
  `back_to_back_policy`, and retain broad `apb_back_to_back_policy_deferred`;
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif` and
  `.apb` are 16-bit, expose `protection_policy`, have no aggregate
  `back_to_back_policy`, and retain broad `apb_back_to_back_policy_deferred`;
- a temporary data16-protection adjacent-setup standalone completer candidate
  fails at the current timing guard, which still accepts only the previously
  selected no-sideband, sideband, sideband multi-register no-policy,
  protection-only, or data16 no-policy timing families.

## Why Data16-Protection Contract Selection Next

The bounded data16-protection contract is the next safest owner because the
independent prerequisites now ship:

- `.625` proved selected 16-bit requester queueing, `PSTRB width 2`, data16
  adjacent setup, and data16 fixed-composition propagation without protection
  side effects;
- `.628` proved selected protected adjacent setup and fixed-composition
  propagation without width changes;
- `.622` proved the shared sideband-aware two-register adjacent setup and
  fixed-composition timing prerequisite;
- `.603/.597` proved register-local `PPROT[0]` allow/deny behavior,
  zero-strobe semantics, and fixed-composition propagation.

Combining data16 and protection next is narrower than multi-peripheral
multi-register timing propagation, deeper queues, alternate overflow, or
multiple active APB transfers. It should focus on one standalone protected
data16 two-register completer plus one fixed one-requester/one-completer
composition that combines the already shipped data16 requester timing with
the already shipped data16-protection register policy shape.

## `.630` Contract-Selection Questions

`.630` must select the exact public contract before implementation, including:

- whether the selected public sources are limited to a standalone completer
  and fixed composition, or whether any requester alias also needs a new
  support-accounted source;
- exact `.ppif` and `.apb` sample names, likely using
  `apb_completer_multi_register_sideband_data16_protection_back_to_back` and
  `apb_composition_multi_register_sideband_data16_protection_status_back_to_back`
  suffixes if no better name is found;
- the exact data16 protected register shape: 32-bit address, 16-bit data,
  `PSTRB width 2`, `PPROT width 3`, `reg0` at byte address `0`, `reg1` at
  byte address `2`, and the selected register-local privileged policies;
- requester requirements for `accepted`, `busy`, `status width 2`, `done`,
  `last_error`, `last_read_data width 16`, `req_prot width 3`, and
  `req_wstrb width 2`;
- report and residue movement for `back_to_back_policy`, `width_policy`, and
  `protection_policy`;
- diagnostics for wrong addresses, widths, sidebands, access policies,
  endpoint compatibility, queue depth, overflow policy, and accepted-less
  requester attempts;
- validation gates, docs/mdBook wording, support-accounting identities,
  rollback, and explicit residue.

## Deferred Work

This selection does not include multi-peripheral data16-protection timing
propagation, broader multi-peripheral multi-register timing propagation,
queue depths greater than `1`, overflow policies other than `reject`,
accepted-less requester surfaces, multiple active APB bus transfers,
additional `PPROT` predicates, global/window/interconnect-owned protection
policies, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

## Validation

Focused validation for this selector is documentation and live-report based:

```bash
perl -MJSON::PP -e '...' \
  ppif/apb_completer_multi_register_sideband_data16_protection.ppif \
  ppif/apb_composition_multi_register_sideband_data16_protection.ppif \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
```

A temporary data16-protection adjacent-setup candidate was generated under
`/tmp` and rejected by the current guard. Closeout runs Knowledge Map
generation/check, mdBook build, docs path, memory, diff, and doctrine gates.
