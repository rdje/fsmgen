---
id: ial2-axi-manager-read-response-demux-behavior-readiness-audit
title: AXI read response demux behavior can implement directly
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.40 decide?"
  - "does generated read RID demux need an IAL1 prerequisite?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.41?"
  - "what is the next read response-demux behavior slice?"
  - "did IAL2-FEATURE-COMPLETENESS-FRONTIER.41 ship?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, behavior, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.40|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.41|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE|generated read.*RID|bounded generated single-beat read' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.40` audited generated read `RID`
response-demux behavior readiness after the shipped read parser/report
metadata. It concluded that bounded single-beat generated read `RID` demux can
be implemented directly; no new IAL1, IAL0, or SystemVerilog prerequisite is
required because the shipped IAL1 `(pulse TARGET)` action and generated write
demux path already provide the needed layered shape.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.41` later shipped that implementation. It
made response-demux helpers family-aware, added the read response ID as a
generated input, reclassified selected read transaction completion names as
generated pulse outputs under the explicit read `response-demux` opt-in, kept
raw top-level `read-complete` as the accepted read-response event input,
emitted read demux rules/assertions, and drove read capacity release plus
auto-ID release from the generated completion pulses.

Read-data payload capture, read-data interleaving/reassembly, bursts/`RLAST`,
per-ID response queues, queued/blocking policy, full-manager behavior, direct
backend lowering, and VHDL remain future exact-owner work.
