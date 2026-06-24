---
id: ial2-dynamic-recapture-support-detail-alignment
title: Dynamic recapture support detail matches shipped read burst-last recapture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.375 change?"
  - "does the generated dynamic support detail include read burst-last recapture?"
  - "why was dynamic recapture support prose aligned before multiple dynamic recapture?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.376?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-cycle, recapture, support-detail]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.375|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.376|AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT|single-active dynamic read ID capture plus single-beat RID response matching and burst-last RID/RLAST response matching including same-cycle release-and-recapture|same-cycle recapture outside single-active dynamic write BID demux, single-active dynamic read single-beat RID demux, and single-active dynamic read burst-last RID/RLAST demux|without release-and-recapture' docs/AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.375` aligns the generated
`dynamic_transaction_id_behavior` support-detail prose with the shipped
single-active dynamic read burst-last release-and-recapture behavior from
`IAL2-FEATURE-COMPLETENESS-FRONTIER.372`.

The generated support detail now says single-active dynamic read ID capture
supports single-beat `RID` and burst-last `RID/RLAST` response matching
including same-cycle release-and-recapture. It also leaves same-cycle
recapture future work only outside the selected single-active dynamic write
`BID`, read single-beat `RID`, and read burst-last `RID/RLAST` demux
boundaries.

The slice changes report/support prose and focused expectations only. Parser
syntax, PPIF samples, support-accounting identities, response-demux semantics,
generated state/rules/assertions, HDL, and runtime behavior are unchanged.

After `.375`, the frontier advances to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.376`, selection of the first multiple
all-dynamic release-and-recapture contract owner.
