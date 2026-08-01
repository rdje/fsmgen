---
id: ial2-post-apb-requester-transfer-next-slice-selection
title: APB .apb profile-alias readiness was selected after APB PPIF requester-transfer
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.551 select?"
date: 2026-06-26
status: historical
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: >-
  docs/IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; ppif/apb_requester_transfer.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md;
  docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.551|IAL2-FEATURE-COMPLETENESS-FRONTIER\.552|APB \.apb profile-alias readiness|known unsupported IAL2 alias candidate|source_kind => .ppif.|source_kind => .ial2_profile_alias.|unsupported_first_slice_aliases|must not accept \.apb' docs/IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.551` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.552`, an APB `.apb` profile-alias
readiness audit after the first APB `.ppif` requester-transfer behavior.

The APB `.ppif` evidence is now real: `ppif/apb_requester_transfer.ppif`
uses `(profile apb)` with one `(apb-requester apb_requester ...)`, lowers
through generated `apb_requester.isf` before `apb_requester.fsm`, emits report
schema `fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, and
support-accounts `intent.ppif_apb_requester_transfer`.

`.apb` was not accepted by `.551`. `.552` owned the readiness audit and
remained prohibited from changing parser/generator behavior or accepting any
new suffix.
