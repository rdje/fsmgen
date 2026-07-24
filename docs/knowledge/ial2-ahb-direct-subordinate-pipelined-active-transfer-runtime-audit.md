---
id: ial2-ahb-direct-subordinate-pipelined-active-transfer-runtime-audit
title: Direct AHB subordinate seed drops active phases accepted on completion edges
answers:
  - "does the direct fsm ahb_lite_subordinate seed retain consecutive active address phases?"
  - "what happens when the direct AHB subordinate accepts an active phase on successful completion?"
  - "what happens when the direct AHB subordinate accepts an active phase on final ERROR?"
  - "is the direct AHB subordinate seed repaired by the generated-family phase pipeline?"
  - "which task owns the direct AHB subordinate phase-retention contract?"
date: 2026-07-23
status: current
tags: [ahb, subordinate, direct-seed, pipeline, phase, generated-hdl, correctness, bug, audit]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

The unchanged direct lower-layer `fsm/ahb_lite_subordinate.fsm` seed samples
address/control only in `IDLE`. t/1520 proves that successful `ACCESS` and
final `ERROR_COMPLETE` ready edges each accept a held selected active phase at
the bus but return to IDLE without capturing it.

The success case records two bus acceptances, one internal capture/completion,
no error, and only the first write value `0x11111111`. The final-ERROR case
records two acceptances, one capture/completion, exactly two ERROR cycles, and
zero storage. This direct seed is separate from the generated IAL2 family
repaired by `.3`. `.5` now selects atomic direct-state capture/dispatch through
the existing registers, and `.6` owns implementation. Decision 0020 remains
inactive.
