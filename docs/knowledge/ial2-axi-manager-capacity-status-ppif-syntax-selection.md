---
id: ial2-axi-manager-capacity-status-ppif-syntax-selection
title: AXI manager capacity/status public PPIF syntax selected
answers:
  - "what is the planned .ppif syntax for AXI manager capacity/status?"
  - "is public .ppif AXI manager capacity/status ready to implement?"
  - "what should the next AXI manager capacity/status PPIF leaf implement?"
  - "can AXI manager capacity/status PPIF mix with valid-ready-channel objects?"
  - "which public surfaces must change for AXI manager capacity/status PPIF?"
date: 2026-06-12
status: current
tags: [ial2, ppif, axi, manager, capacity, status, syntax, readiness]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'manager-capacity-status|axi_manager_capacity_status|IAL2-FEATURE-COMPLETENESS-FRONTIER.6|ppif/axi_manager_capacity_status.ppif|mixing.*valid-ready-channel' docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

Public `.ppif` syntax for the AXI manager capacity/status object is selected
as one `(manager-capacity-status NAME ...)` object under a generic
`(protocol-platform-intent ...)` root with `(profile axi4)` and top-level
source anchors. The selected fields map to the shipped in-process
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` contract: explicit
read/write `max-pending`, `submit-policy try`, abstract read/write submit and
completion events, reset/clock, and optional namespaced status outputs.

The next implementation leaf should support exactly one
`manager-capacity-status` object per `.ppif` file, with parser/CLI behavior,
a runnable sample, support-accounting corpus entry, language-surface/capability
manifest update, check JSON and normalized semantic JSON public source
identity, focused diagnostics, mdBook sync, and Knowledge Map sync. Mixing
with `valid-ready-channel`, multiple manager objects, IDs, ordering, response
matching, bursts, queued/blocking policy, profile aliases, and VHDL remain
rejected in the first public capacity/status slice.
