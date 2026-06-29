---
id: ial2-ahb-profile-alias-contract-selection
title: AHB .ahb public profile-alias contract selects bounded implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.699 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.700?"
  - "what is the AHB .ahb public profile-alias contract?"
  - "is .ahb ready after AHB requester PPIF?"
  - "how should AHB .ahb be support-accounted?"
date: 2026-06-29
status: historical
tags: [ial2, ahb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_AHB_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_READINESS_AUDIT.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/IAL2_AHB_REQUESTER_PPIF_PUBLIC_CONTRACT_SELECTION.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1473-ial2-ahb-requester.t; t/1474-ial2-ahb-profile-alias.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/16c-ial2-ahb.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb && ./bin/fsmgen --quiet --capability-manifest && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.699|IAL2-FEATURE-COMPLETENESS-FRONTIER\.700|AHB \.ahb public profile-alias contract|ppif/ahb_requester\.ahb|intent\.ahb_profile_alias_requester|ial2_ahb_profile_alias_requester_pipeline_cli|source_kind.*ial2_profile_alias|shipped_bounded_profile_alias' docs/IAL2_AHB_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/16c-ial2-ahb.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm t/1474-ial2-ahb-profile-alias.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.699` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.700`, bounded implementation of the first
AHB `.ahb` profile-alias suffix.

The selected public contract mirrors `ppif/ahb_requester.ppif` at the future
alias path `ppif/ahb_requester.ahb`. The `.ahb` source remains the same IAL2
`protocol-platform-intent` form and must keep explicit `(profile ahb)`; the
suffix does not infer the profile.

The first implementation is bounded to exactly one
`(ahb-requester amba_requester ...)` object, generated
`amba_requester.isf`, generated `amba_requester.fsm`, report schema
`fsmgen.ial2.protocol_intent.ahb_requester.v1`, and HDL module
`amba_requester`.

At the end of `.699`, FSMGen still did not accept `.ahb`; `.700` owned the
implementation and has now shipped it. The selected alias support-accounting
identity is
`intent.ahb_profile_alias_requester`, coverage key
`ial2_ahb_profile_alias_requester_pipeline_cli`, and source kind
`ial2_profile_alias`.
