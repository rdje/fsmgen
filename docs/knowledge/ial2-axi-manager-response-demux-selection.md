---
id: ial2-axi-manager-response-demux-selection
title: AXI manager response demux readiness follows bounded auto-ID request drive
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.24 select?"
  - "what comes after AXI auto-ID request-ID drive?"
  - "is AXI response demux next?"
  - "why not implement same-ID ordering before response demux?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, id, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md; docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.24|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.25|response-demux readiness|BID|RID|completion-event direction' docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.24` selected AXI manager generated
response-demux readiness as the next exact subset after bounded auto-ID
request-ID drive.

The reason is that `.23` makes request IDs generated and stores the selected
ID per auto-ID transaction, but completion release still depends on authored
per-transaction completion events. Response demux is the next required audit
before FSMGen can claim generated response matching from `BID`/`RID` evidence.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.25` owns the readiness audit. It must
decide public syntax, response-channel handshake ownership, whether completion
events remain external or gain generated demux signals, response ID input
direction, generated `.isf`/`.fsm`/HDL impact, report shape, diagnostics,
rollback, and remaining residue.

Same-ID ordering, read-data interleaving/reassembly, bursts, queued policy,
aliases, full-manager syntax, and VHDL remain future exact-owner work until
the response-demux readiness audit records a stronger ordering.
