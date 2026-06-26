---
id: ial2-apb-ppif-source-shape-contract-selection
title: APB requester transfer is selected as the first APB PPIF source shape
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.549 select?"
  - "what is the first APB .ppif source shape?"
  - "what APB .ppif sample path is selected?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, source-shape, task-tree]
evidence: docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md; docs/APB_REQUESTER_CAPTURE_WORKSHEET.md; isf/apb_requester.isf; fsm/apb_requester.fsm; fsm/apb_completer.fsm; fsm/apb_tb.fsm; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.549|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.550|ppif/apb_requester_transfer\\.ppif|intent\\.ppif_apb_requester_transfer|profile apb|apb-requester|apb_requester_transfer\\.v1|must not accept \\.apb' docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.549` selects `(profile apb)` plus one
`(apb-requester apb_requester ...)` object as the first APB `.ppif` source
shape. The selected future sample path is `ppif/apb_requester_transfer.ppif`
and the support identity is `intent.ppif_apb_requester_transfer`.

The selected report schema is
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, with generated review
artifacts `apb_requester.isf` and `apb_requester.fsm`.

`.549` selects `.550`, direct bounded implementation of that APB `.ppif`
contract. `.550` must not accept `.apb` or any other new suffix.
