---
id: ial2-mixed-auto-id-queue-head-response-demux-readiness
title: IAL2 mixed auto-ID queue-head response-demux is ready for direct bounded implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.193 select?"
  - "is mixed auto-ID plus concrete queue-head response-demux ready?"
  - "what blocks same-family mixed auto-ID plus queue-head response-demux?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.194?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.193|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.194|MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT|same-family mixed auto-ID|concrete same-ID queue-head' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.193` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.194`, direct bounded implementation of
same-family mixed auto-ID lifecycle plus concrete same-ID queue-head
response-demux for response-demux-only shapes.

The readiness audit found no parser, grammar, IAL1, IAL0, or SystemVerilog
prerequisite. The current blocker is local: the AXI manager response-demux
family model currently chooses either auto-ID response-demux states or
queue-head response-demux states, and must be widened to normalize, generate,
report, and assert over the combined state set.

`.194` must still defer read-data consumption, group-local simultaneous
enqueue widening, packed burst-vector outputs, alternate full burst payload
assembly, direct backend lowering, verification-output generation, VHDL, and
backend-language variants.
