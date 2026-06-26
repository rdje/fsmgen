---
id: ial2-apb-completer-interconnect-contract-selection
title: APB completer/interconnect contract splits completer before interconnect
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.559 select?"
  - "what is the first APB completer IAL2 contract?"
  - "does .559 select APB completer implementation?"
  - "does .apb expose APB completer yet?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; ppif/apb_completer.ppif; fsm/apb_completer.fsm; fsm/apb_tb.fsm; isf/apb_requester.isf; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.559|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.562|apb-completer|ppif/apb_completer\\.ppif|intent\\.ppif_apb_completer|apb_interconnect_generation_deferred|\\.apb.*requester-transfer only' docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.559` selects a split APB
completer/interconnect contract path.

The first selected public contract is `.ppif` APB completer generation at
`ppif/apb_completer.ppif`, with object `(apb-completer apb_completer ...)`,
report schema `fsmgen.ial2.protocol_intent.apb_completer.v1`, generated review
artifacts `apb_completer.isf` and `apb_completer.fsm`, and support identity
`intent.ppif_apb_completer`.

`.559` did not select implementation. It selected `.560`, a no-behavior
generated-IAL1 substrate audit, because the existing APB completer evidence was
an authored `.fsm` fixture and the public contract had to preserve generated
`.isf` before generated `.fsm`. The selected completer behavior later shipped
in `.562`; this card remains the contract-selection fact, while
`docs/knowledge/ial2-apb-ppif-completer-behavior.md` is the behavior fact.

The `.apb` alias remains requester-transfer only until a later alias owner
selects APB completer exposure.
