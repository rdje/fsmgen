---
id: ial2-apb-data16-pprot-effects-behavior
title: APB data16 PPROT policy behavior ships sideband_data16_protection
answers:
  - "does APB data16 PPROT enforce access control now?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.603?"
  - "what APB data16 PPROT policy samples are supported?"
  - "what residue remains after APB data16 PPROT?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, data16, behavior, task-tree]
evidence: >-
  docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_CONTRACT_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; ppif/apb_completer_multi_register_sideband_data16_protection.ppif; ppif/apb_completer_multi_register_sideband_data16_protection.apb; ppif/apb_composition_multi_register_sideband_data16_protection.ppif; ppif/apb_composition_multi_register_sideband_data16_protection.apb; ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t;
  t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_data16_protection.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_data16_protection.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.603` ships the selected
`sideband_data16_protection` APB behavior.

The supported sample pairs are the data16 protection completer, fixed
composition, and multi-peripheral composition `.ppif`/`.apb` files. They keep
16-bit `PWDATA`/`PRDATA`/register data, 2-bit `PSTRB`, 3-bit `PPROT`, 32-bit
addresses, 4-bit wait counts, and two-byte register/window alignment.

Sideband-aware data16 multi-register completers now accept register-local
`(access-policy ...)` clauses with read/write `allow` or `require (privileged
0|1)`. `privileged` means sampled `PPROT[0] == VALUE`. Denied mapped reads
complete with `PREADY=1`, `PSLVERR=1`, and zero 16-bit read data. Denied
mapped writes complete with `PSLVERR=1` and leave storage unchanged, including
when `PSTRB=0`.

Reports keep `width_policy.selected_contract = sideband_data16`, add
`protection_policy`, remove `apb_protection_policy_effects_deferred` from the
selected data16 protection samples, and keep broader work explicit through
`apb_additional_protection_policies_deferred`, `apb_remaining_widths_deferred`,
and `apb_back_to_back_policy_deferred`.
