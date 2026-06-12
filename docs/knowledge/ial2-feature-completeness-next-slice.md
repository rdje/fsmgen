---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is the post response-demux selector
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after generated AXI write BID response demux?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing the next AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.31|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.30|generated write BID response-demux behavior|generated_behavior: true|next exact IAL2 feature-completeness' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
transaction-envelope metadata, transaction event dispatch, concrete
transaction ID assertion, auto-ID lifecycle metadata, bounded auto-ID
request-ID drive, write response-demux metadata, IAL1 rule-pulse action, and
generated write `BID` response-demux behavior, the next active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.31`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.30` shipped generated write `BID`
response-demux behavior. Explicit write response-demux contracts now generate
the response ID input, generated transaction completion pulse outputs,
guarded IAL1 demux rules, active/unique match assertions, and
`response_demux.generated_behavior: true`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.31` is a selector. It must read the
current shipped IAL2 surfaces, AXI manager residue, reports, diagnostics,
generated `.isf`/`.fsm`/SystemVerilog artifacts, mdBook, roadmap, and
Knowledge Map, then choose one next exact IAL2 behavior subset or prerequisite
before any further behavior changes.

The full AXI manager is not implemented yet. Read `RID` demux, same-ID
ordering, read-data interleaving/reassembly, bursts, queued/blocking policy,
profile aliases, full-manager syntax, and VHDL remain future exact-owner work.
VHDL stays deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is
feature-complete enough to reopen backend parity.
