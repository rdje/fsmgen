---
id: ial2-apb-profile-alias-public-surface-sync
title: APB profile-alias docs now include PPROT protection aliases
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.599?"
  - "are APB .apb protection aliases documented?"
  - "does APB profile-alias documentation include PPROT access policies?"
  - "what APB profile-alias cleanup followed .597?"
  - "what comes after APB profile-alias public sync?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, profile-alias, public-surface, docs, task-tree]
evidence: docs/IAL2_APB_PROFILE_ALIAS_PUBLIC_SURFACE_SYNC.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_POST_APB_PPROT_ACCESS_POLICY_NEXT_SLICE_SELECTION.md; docs/knowledge/ial2-post-apb-pprot-access-policy-next-slice-selection.md; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'intent\.apb_profile_alias_completer_multi_register_sideband_protection|intent\.apb_profile_alias_composition_multi_register_sideband_protection|intent\.apb_profile_alias_composition_multi_peripheral_sideband_protection|data16 protection-policy effects|apb_additional_protection_policies_deferred|apb_protection_policy_effects_deferred' docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md && prove -Iperl t/1470-ial2-apb-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.599` synchronizes the APB `.apb`
profile-alias public documentation after `.597` shipped bounded APB `PPROT`
register-local access-policy behavior.

`docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` now documents the selected protection
alias support-accounting entries for completer, fixed composition, and
multi-peripheral composition. Its CLI examples include protection aliases, its
report text explains that selected protection aliases carry
`protection_policy` plus `apb_additional_protection_policies_deferred`, and its
non-goals now defer the narrower remaining surfaces: data16 policy effects,
additional predicates, global/window/peripheral policies, interconnect-owned
enforcement, and back-to-back transfer policy.

`.599` changes no parser behavior, generator behavior, source samples,
support-accounting catalog entries, validation behavior, generated artifacts,
report schemas, schedule/check/semantic JSON behavior, HDL/runtime behavior,
suffix acceptance, direct backend lowering, verification-output generation,
backend-language variants, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior.

`.600` is the next no-behavior selector after the APB profile-alias public
surface is aligned.
