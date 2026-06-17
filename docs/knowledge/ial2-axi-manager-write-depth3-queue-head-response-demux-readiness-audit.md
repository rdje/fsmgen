---
id: ial2-axi-manager-write-depth3-queue-head-response-demux-readiness-audit
title: Write depth-3 queue-head response-demux readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.170 select?"
  - "is write depth-3 queue-head response-demux ready to implement?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.171?"
  - "what should generated write depth-3 queue-head response-demux cover?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, write, response-demux, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.170|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.171|WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT|write_depth3_same_id_queue_head_response_demux|generated_write_bid_queue_head_demux|54 queue update rules' docs/AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.170` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.171`, direct bounded implementation of
generated write-family depth-3 concrete same-ID queue-head response-demux.

The audit found no parser, IAL1, IAL0, SystemVerilog lowerer,
support-accounting framework, or mdBook prerequisite. Existing write depth-2
one-group and multi-group queue-head response-demux samples are generated,
and read depth-3 queue-head siblings prove the shared queue-state machinery
already handles three slots. A temporary write depth-3 candidate passes
strict check with no diagnostics and remains selected-not-generated only at
`generated_same_id_queue_head_demux`.

`.171` should add one public sample for `w0`/`w1`/`w2` sharing concrete
`BID` `3`, generate three write completion outputs and response-demux rules,
9 queue slot storage signals, 54 queue update rules, 14 queue assertions, and
4 write response-demux assertions. It must not enable multiple or mixed
depth-3 groups, mixed auto-ID, group-local enqueue widening, read-data,
burst-length, runtime-validation, direct backend, verification-output
generation, VHDL, or backend-language variants.
