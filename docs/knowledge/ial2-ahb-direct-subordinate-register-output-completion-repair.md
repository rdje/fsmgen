---
id: ial2-ahb-direct-subordinate-register-output-completion-repair
title: Direct AHB subordinate retains completion-edge active phases through Q-named state
answers:
  - "does the direct fsm ahb_lite_subordinate retain consecutive active address phases now?"
  - "how does the direct AHB subordinate capture a phase on successful completion?"
  - "how does the direct AHB subordinate handle active continuation after final ERROR?"
  - "does the repaired direct AHB subordinate use a pending bank or relaunch state?"
  - "does the direct AHB subordinate capture HWDATA with address control?"
  - "what did IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.8 repair?"
date: 2026-07-23
status: current
tags: [ahb, subordinate, direct-seed, pipeline, phase, register-out, generated-hdl, correctness, repair]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

The direct seed now uses Q-named `<-` loads for its existing four-state phase
and storage registers. Current completion reads registered Q while same-edge
capture writes separate generated `*_next` values. Successful and final-ERROR
ready edges retain accepted NONSEQ or SEQ exactly once; IDLE/BUSY/unselected
cancels continuation.

t/1520 proves four exact success/ERROR/SEQ/IDLE scenarios, warning-clean HDL,
no pending bank/relaunch, live HWDATA ownership, and one capture/completion per
bus acceptance. The support identity, four states, ports/artifact, generated
IAL2 family, and decision 0020 remain unchanged.
