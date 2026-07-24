---
id: ial2-ahb-direct-subordinate-register-output-completion-contract-selection
title: Direct AHB completion repair will use Q-named register-output assignment
answers:
  - "what is the selected lowering-safe direct AHB subordinate completion repair?"
  - "will the direct AHB subordinate repair add a pending bank or relaunch state?"
  - "why does the direct AHB repair use the <- assignment operator?"
  - "how will the direct AHB subordinate retain active NONSEQ or SEQ on completion?"
  - "what does IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.7 select?"
  - "which task implements the direct AHB register-output completion repair?"
date: 2026-07-23
status: current
tags: [ahb, subordinate, direct-seed, pipeline, phase, register-out, contract, correctness]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'Why Q-Named Assignment|Selected Completion Dispatcher|UNOPTFLAT|success \+ active NONSEQ|IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.8' docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md
---

`.7` selects the existing four-state direct dispatcher with every persistent
phase/storage load expressed as Q-named `<-`. Lowering reads registered
`write_q` for current completion and writes separate `write_q_next` from the
next phase's HWRITE, so a following read cannot suppress the completing write.

No pending bank, relaunch state, extra stall, HWDATA capture, public surface,
or report is added. A warning-clean disposable candidate passes active NONSEQ
after success/final ERROR, active SEQ after success, and IDLE cancellation
after final ERROR with exact acceptance/capture/completion and two-cycle ERROR
counts. The D-input-named bank/relaunch fallback was rejected for Verilator
`UNOPTFLAT` and avoidable latency. `.8` owns implementation; the shipped direct
seed remains unrepaired until then.
