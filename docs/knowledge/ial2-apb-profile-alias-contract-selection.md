---
id: ial2-apb-profile-alias-contract-selection
title: APB .apb public profile-alias contract selects direct bounded implementation
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.553?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.553 select?"
  - "what is the APB .apb public profile-alias contract?"
  - "is .apb ready after APB .ppif requester-transfer?"
date: 2026-06-26
status: historical
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_FIRST_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; ppif/apb_requester_transfer.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1469-ial2-axi-profile-alias.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.553|IAL2-FEATURE-COMPLETENESS-FRONTIER\.554|APB \.apb public profile-alias contract|ppif/apb_requester_transfer\.apb|intent\.apb_profile_alias_requester_transfer|ial2_apb_profile_alias_requester_transfer_pipeline_cli|source_kind => .ial2_profile_alias.|known unsupported IAL2 alias candidate' docs/IAL2_APB_PROFILE_ALIAS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1469-ial2-axi-profile-alias.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.553` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.554`, direct bounded implementation of the
first APB `.apb` profile-alias suffix.

The selected public contract mirrors `ppif/apb_requester_transfer.ppif` at the
future alias path `ppif/apb_requester_transfer.apb`. The `.apb` source remains
the same IAL2 `protocol-platform-intent` form and must keep explicit
`(profile apb)`; the suffix does not infer the profile.

The first implementation is bounded to exactly one
`(apb-requester apb_requester ...)` requester-transfer object, generated
`apb_requester.isf`, generated `apb_requester.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, and HDL module
`apb_requester`.

At the end of `.553`, FSMGen still did not accept `.apb`; `.554` owned the
implementation. The selected alias support-accounting identity was
`intent.apb_profile_alias_requester_transfer`, coverage key
`ial2_apb_profile_alias_requester_transfer_pipeline_cli`, and source kind
`ial2_profile_alias`.

Current `.apb` behavior is tracked by
`docs/knowledge/ial2-apb-profile-alias-behavior.md`.
