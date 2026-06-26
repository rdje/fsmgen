---
id: ial2-apb-completer-generated-ial1-substrate-audit
title: APB completer generation needs an IAL1 expression entry-guard prerequisite
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.560 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.560?"
  - "what blocks APB completer generated IAL1?"
  - "why does APB completer need an IAL1 prerequisite?"
date: 2026-06-26
status: current
tags: [ial2, ial1, apb, ppif, task-tree]
evidence: docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_READINESS_AUDIT.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; fsm/apb_completer.fsm; fsm/apb_tb.fsm; isf/apb_requester.isf; isf/storage_fields.isf; isf/burst_reader.isf; docs/book/src/13b-transactions.md; docs/book/src/13d-control-flow.md; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.560|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.561|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.562|ARRAY\\(\\.\\.\\.\\)|expression entry|PSEL.*PENABLE|apb_completer\\.isf|intent\\.ppif_apb_completer' docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.560` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.561`, an IAL1 expression entry-activation
guard rendering prerequisite, before direct APB `.ppif` completer
implementation.

The selected APB completer contract targeted `ppif/apb_completer.ppif`,
`(apb-completer apb_completer ...)`, `apb_completer.isf`,
`apb_completer.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and support identity
`intent.ppif_apb_completer`. That behavior later shipped in `.562`.

At `.560` closeout, direct implementation was blocked because the required
setup detector `PSEL && !PENABLE` had to be expressed as transaction entry
`(when EXPR (sample ...))`. Generated IAL1 lowering could render scalar entry
guards, but expression entry guards produced invalid generated `.fsm` guard
suffixes containing `ARRAY(...)`. `.561` repaired that IAL1 guard
serialization; `.562` then shipped the APB completer behavior. This card
remains the prerequisite audit fact, while
`docs/knowledge/ial2-apb-ppif-completer-behavior.md` is the behavior fact.
