---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is the post-output-bank AXI selector
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.73?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.75?"
  - "what must happen before the next AXI manager behavior?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, output-bank, selector, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.74|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.75|multi-beat read-data output-bank behavior|multi_beat_reassembly_generated_behavior' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.74` shipped generated AXI multi-beat
read-data output-bank behavior. The public multi-beat sample now generates
`RDATA`/`RRESP` payload inputs, per-transaction data/status lane outputs,
valid masks, length outputs, request-time output-bank clearing, lane capture
rules, and generated artifact report fields. Schedule JSON reports
`multi_beat_reassembly_generated_behavior: true`, and read-data residue is
reduced to `rresp_aggregation`.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.75`. It is a
selector, not a behavior change. It must choose the next exact AXI manager
feature-completeness owner from the remaining scalar `RRESP` aggregation,
per-ID read-data queues, authored concrete-ID same-ID ordering,
queued/blocking policy, profile aliases, full-manager behavior, direct
backend lowering, VHDL/reroute work, report/static alignment, another
readiness audit, or an IAL1/IAL0/SystemVerilog prerequisite.

No parser, generator, HDL, sample, support-accounting, check JSON, semantic
JSON, or validation behavior change is owned by `.75` unless the selector
creates a later exact behavior owner first.
