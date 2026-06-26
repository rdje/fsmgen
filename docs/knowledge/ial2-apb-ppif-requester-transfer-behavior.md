---
id: ial2-apb-ppif-requester-transfer-behavior
title: APB requester-transfer is shipped as a PPIF source shape
answers:
  - "does FSMGen support an APB .ppif source?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.550 implement?"
  - "what APB PPIF behavior is shipped?"
  - "does APB PPIF accept .apb?"
  - "what report schema does APB requester-transfer use?"
date: 2026-06-26
status: current
tags: [ial2, apb, ppif, requester, behavior, task-tree]
evidence: docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; ppif/apb_requester_transfer.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --strict --check --json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --strict --emit-semantic-json ppif/apb_requester_transfer.ppif && prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.550` ships the first APB `.ppif`
requester-transfer behavior. The public sample is
`ppif/apb_requester_transfer.ppif`, using `(profile apb)` and one
`(apb-requester apb_requester ...)` object.

The APB `.ppif` source generates review artifacts `apb_requester.isf` and
`apb_requester.fsm` through IAL1 before IAL0, then reaches the existing HDL
path with module `apb_requester`.

The IAL2 report schema is
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, and support accounting
matches `intent.ppif_apb_requester_transfer`.

`.apb` remains a known unsupported suffix. APB support in `.550` is an APB
profile inside `.ppif`, not a new suffix and not an AXI extension.
