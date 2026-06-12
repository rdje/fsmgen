---
id: ial2-axi-manager-read-data-contract-selection
title: AXI read-data contract uses single-beat RDATA and RRESP capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.44 select?"
  - "what is the AXI read-data syntax?"
  - "what is the read-data payload contract?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.44?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.45?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, single-beat, contract, parser, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.44|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.45|read-data|capture-scope single-beat|completion-source response-demux|single-beat-by-rid' docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.44` selected an explicit optional
`read-data` clause under `manager-capacity-status` for bounded single-beat
`RDATA`/`RRESP` capture.

The selected source shape is:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))))
```

The generated read response-demux completion pulse is the data/status validity
strobe for the selected transaction. The raw top-level `read-complete` event
remains the accepted single-beat response transfer event.

The first contract requires generated read response-demux, positive read ID
metadata, read auto-ID lifecycle metadata, a positive `RDATA` width, 2-bit
`RRESP` status width, and transaction output bindings. It rejects `RLAST`,
bursts, multi-beat reassembly, explicit output widths, unsupported
interleaving policies, and direct generated data-capture behavior.

The next leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.45`, parser/report
metadata and static validation for this contract. Generated `RDATA`/`RRESP`
capture behavior remains a later exact owner.
