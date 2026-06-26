---
id: ial2-first-profile-alias-contract-selection
title: The first IAL2 profile-alias contract selects .axi as an explicit-profile alias
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.539 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.540?"
  - "which profile-alias suffix is first?"
  - "does selecting .axi make IAL2 AXI-only?"
  - "what should the first .axi alias require?"
date: 2026-06-26
status: current
tags: [ial2, profile-alias, axi, contract-selection, task-tree]
evidence: docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_PROFILE_ALIAS_UNSUPPORTED_INVENTORY_SYNC.md; docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_aw_valid_ready.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.539|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.540|ppif/axi_aw_valid_ready\\.axi|intent\\.axi_profile_alias_aw_valid_ready|ial2_axi_profile_alias_aw_valid_ready_pipeline_cli|AXI is the first shipped IAL2 profile/example, not the definition of IAL2|profile-alias example only' docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-first-profile-alias-contract-selection.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.539` selects `.axi` as the first IAL2
profile-alias contract and advances to `.540` for direct bounded
implementation.

The first `.axi` alias should mirror `ppif/axi_aw_valid_ready.ppif` at
`ppif/axi_aw_valid_ready.axi`, require an explicit AXI-family profile such as
`(profile axi4)`, preserve `IAL2 -> IAL1 -> IAL0` lowering, and be
support-accounted as `intent.axi_profile_alias_aw_valid_ready`. Selecting `.axi`
does not make IAL2 AXI-only; it is only the first profile-alias example.
