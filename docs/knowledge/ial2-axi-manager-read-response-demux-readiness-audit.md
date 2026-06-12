---
id: ial2-axi-manager-read-response-demux-readiness-audit
title: AXI read response demux needs contract selection first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.37 decide?"
  - "can read RID response demux be implemented directly?"
  - "what comes after read response-demux readiness?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.38?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.37|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.38|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.39|read response-demux|response-scope single-beat|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.37` decided not to implement read `RID`
response demux directly. It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`,
a public contract-selection slice.

The reason is contractual, not a missing IAL1 primitive. The current substrate
already has read ID-family metadata, read transaction metadata, read-capable
auto-ID lifecycle state, concrete `ARID`/`RID` assertion reachability, and
IAL1 rule-owned `(pulse TARGET)` actions. However, the public `.ppif` surface
does not yet define whether read `response-event` means an accepted read data
beat, a transaction-level last-beat event, or an already-demuxed completion.
It also does not state whether the first read demux scope is
single-beat/non-burst only.

`.38` must select the exact bounded read response-demux contract, metadata
requirements, report shape, diagnostics, generated artifact boundary, residue,
and VHDL deferral before parser/report metadata or generated behavior changes.
It is now complete: `.38` selected required `(response-scope single-beat)` and
advanced the frontier to `.39`, parser/report metadata and static validation.
