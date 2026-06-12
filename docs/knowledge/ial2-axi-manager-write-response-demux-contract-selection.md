---
id: ial2-axi-manager-write-response-demux-contract-selection
title: AXI write response demux uses explicit response-demux opt-in syntax
answers:
  - "what syntax was selected for AXI write response demux?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.26 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.27?"
  - "do transaction completion names become generated automatically?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'response-demux|transaction-completion generated|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.26|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.27|generated_behavior: false|generated \\.isf.*unchanged' docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.26` selected an explicit optional
`response-demux` clause under `manager-capacity-status`:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

This first contract is write-only. `response-event` names the raw write
response accepted event and must equal top-level `write-complete` in the first
bounded slice. `transaction-completion generated` means write transaction
`completion` names become generated demux signals only when this explicit
opt-in clause is present.

Without `response-demux`, transaction completion names remain authored inputs.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.27` shipped the parser/report metadata and
static-validation implementation first, with generated `.isf`, `.fsm`, and HDL
behavior unchanged. Generated write `BID` demux behavior remains owned by a
later task-tree leaf.
