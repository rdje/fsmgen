# IAL2 Post-APB Sideband Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.623`
- Date: `2026-06-28`
- Status: selected next contract owner
- Scope: APB data16/protection back-to-back timing-policy next-owner
  selection only

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.623` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.624`, public contract selection for the
bounded APB sideband-aware data16 back-to-back timing-policy family, as the
next owner after `.622` shipped the selected 32-bit sideband-aware
multi-register timing prerequisite.

This selector changes no parser behavior, generator behavior, sample files,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix acceptance,
direct backend lowering, verification-output generation, backend-language
variants, APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

The selector read:

- `.622` sideband-aware multi-register back-to-back behavior;
- `.621` sideband-aware multi-register back-to-back contract selection;
- `.620` APB data16/protection back-to-back readiness audit;
- `.618` sideband-aware multi-peripheral back-to-back behavior;
- `.615` sideband completer and fixed-composition back-to-back behavior;
- `.612` sideband requester queued `PPROT/PSTRB` behavior;
- `.607/.606` base APB back-to-back behavior and contract;
- `.603`, `.597`, `.594`, and `.589` APB data16/protection/sideband behavior
  records;
- current APB requester, completer, fixed-composition, and multi-peripheral
  timing-policy guards;
- current reports for representative data16, protection, and
  data16-protection APB sources;
- RegressionCorpus, LanguageSurfaceSection, focused APB/profile-alias/support
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

## Live Report Probe

Live schedule-report probes after `.622` confirmed representative
data16/protection surfaces still have no aggregate `back_to_back_policy` and
still keep broad `apb_back_to_back_policy_deferred`:

```text
ppif/apb_requester_transfer_sideband_data16.ppif:
  data_width=16; protection_policy=no; keeps apb_back_to_back_policy_deferred
ppif/apb_completer_multi_register_sideband_data16.ppif:
  data_width=16; protection_policy=no; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_data16.ppif:
  data_width=16; protection_policy=no; keeps apb_back_to_back_policy_deferred
ppif/apb_completer_multi_register_sideband_protection.ppif:
  data_width=32; protection_policy=yes; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_protection.ppif:
  data_width=32; protection_policy=yes; keeps apb_back_to_back_policy_deferred
ppif/apb_completer_multi_register_sideband_data16_protection.ppif:
  data_width=16; protection_policy=yes; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_register_sideband_data16_protection.ppif:
  data_width=16; protection_policy=yes; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_data16.ppif:
  data_width=16; protection_policy=no; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_protection.ppif:
  data_width=32; protection_policy=yes; keeps apb_back_to_back_policy_deferred
ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif:
  data_width=16; protection_policy=yes; keeps apb_back_to_back_policy_deferred
```

## Guard Findings

After `.622`, the remaining timing-policy guards are concentrated on width,
access policy, and multi-peripheral multi-register shape:

- requester back-to-back timing accepts 32-bit no-sideband or selected 32-bit
  sideband-aware families and still rejects 16-bit requester timing;
- completer adjacent setup accepts selected 32-bit one-register families and
  the selected 32-bit sideband-aware two-register no-policy family, but still
  rejects data16 and register-local `access-policy` timing variants;
- fixed composition accepts selected 32-bit no-sideband or selected 32-bit
  sideband-aware wiring and the selected sideband-aware two-register no-policy
  completer, but still rejects data16 and access-policy timing variants;
- multi-peripheral timing propagation still requires one-register peripheral
  completers, so multi-peripheral multi-register timing remains a separate
  future owner.

## Why Data16 Contract Selection Next

The next owner should be data16-only contract selection, not protection-first
or combined data16-protection behavior.

Data16 is the smaller next axis because it widens the already-shipped sideband
queue and adjacent-completer paths to 16-bit data and `PSTRB width 2` without
adding register-local denied-access side effects. The existing data16
no-policy sources already define the intended width surface: 16-bit
`PWDATA/PRDATA` and register data, two byte lanes, 2-byte register alignment,
3-bit `PPROT`, 2-bit `PSTRB`, 32-bit addresses, and 4-bit wait counts.

Protection-only timing is also important, but it introduces access-policy
effects under adjacent setup: denied reads return zero data with `PSLVERR`,
denied writes are side-effect-free, and zero-strobe denied writes still error.
Those semantics should not be combined with first-time 16-bit requester queue
payload capture or first-time data16 fixed-composition timing propagation in
the same selector.

Combined data16-protection timing remains behind both the data16 timing owner
and a later protection timing owner. Multi-peripheral multi-register timing is
also deferred because `.622` selected only fixed one-requester/one-completer
multi-register propagation.

## `.624` Contract-Selection Questions

`.624` must select the exact public APB data16 timing contract before behavior
changes, including:

- exact `.ppif` and `.apb` sample names;
- whether the first data16 timing slice includes standalone requester,
  standalone completer, fixed composition, or a smaller subset;
- whether the selected requester is the data16 sideband status family with
  `accepted/busy/status`, `req_wdata width 16`, `req_wstrb width 2`, and
  depth-1 queued overflow-reject timing;
- whether the selected completer is the data16 no-policy two-register family
  with `reg0` at address `0`, `reg1` at address `2`, `PSTRB width 2`, and
  adjacent setup admission;
- whether fixed-composition timing propagation is selected together with the
  endpoint surfaces;
- report/residue movement for `apb_back_to_back_policy_deferred`,
  `apb_additional_back_to_back_policies_deferred`,
  `apb_remaining_widths_deferred`, and protection-policy residue;
- support-accounting identities, diagnostics, focused APB/profile-alias tests,
  schedule/check/semantic JSON gates, generated-artifact and HDL-shape gates;
- rollback boundaries and explicit deferral for protection-only timing,
  combined data16-protection timing, multi-peripheral multi-register timing,
  deeper queues, alternate overflow, direct backend, verification-output,
  backend-language variants, AXI, AHB, and VHDL.

## Deferred Work

This selector does not select protection-only timing behavior, combined
data16-protection timing behavior, multi-peripheral multi-register timing
propagation, queue depths greater than `1`, overflow policies other than
`reject`, accepted-less requester surfaces, multiple active APB bus transfers,
bus matrices, scoreboards, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, AHB behavior, or VHDL
behavior.

## Validation

Validation used code/doc review plus the live schedule-report probe:

```bash
perl -MJSON::PP -we '...' \
  ppif/apb_requester_transfer_sideband_data16.ppif \
  ppif/apb_completer_multi_register_sideband_data16.ppif \
  ppif/apb_composition_multi_register_sideband_data16.ppif \
  ppif/apb_completer_multi_register_sideband_protection.ppif \
  ppif/apb_composition_multi_register_sideband_protection.ppif \
  ppif/apb_completer_multi_register_sideband_data16_protection.ppif \
  ppif/apb_composition_multi_register_sideband_data16_protection.ppif \
  ppif/apb_composition_multi_peripheral_sideband_data16.ppif \
  ppif/apb_composition_multi_peripheral_sideband_protection.ppif \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
```

Closeout also runs Knowledge Map generation/check, mdBook build, docs path,
memory, diff, and doctrine gates.

## Rollback

Rollback is doc-only: revert this selector, its fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map changes. The `.622`
sideband-aware multi-register back-to-back behavior and all existing APB, AXI,
AHB, and VHDL behavior remain unchanged.
