---
id: ial2-ahb-direct-subordinate-pipelined-active-transfer-contract-selection
title: Direct AHB subordinate will capture and dispatch the next phase on completion
answers:
  - "what is the selected direct AHB subordinate completion-edge repair contract?"
  - "does the direct AHB subordinate need a pending queue to retain the next phase?"
  - "which fields will the direct AHB subordinate capture on completion?"
  - "how will the direct AHB subordinate handle active continuation after final ERROR?"
  - "does the direct AHB subordinate contract capture HWDATA?"
  - "which task implements the direct AHB subordinate phase repair?"
date: 2026-07-23
status: current
tags: [ahb, subordinate, direct-seed, pipeline, phase, contract, correctness]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'Selected Completion Dispatcher|HWDATA Ownership|bus_accepts=2|ERROR_COMPLETE|IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.6' docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md
---

The selected direct-seed repair atomically dispatches a selected active phase
on successful or final-ERROR completion. NONSEQ loads existing addr_q,
write_q, size_q, and wait_ctr and enters ACCESS; SEQ preserves the current
unsupported policy by loading wait_ctr and entering UNSUPPORTED. IDLE, BUSY,
or unselected input enters IDLE without capture.

No pending queue is required because the direct state completes on the same
edge and its existing registers can immediately represent the next data phase.
HWDATA is never address-phase captured: the completing write consumes its old
live data, and the next write data is presented after the edge. `.6` owns
implementation and must convert t/1520 to two acceptances/captures/completions,
preserving exactly two initial ERROR cycles and all generated-family behavior.
