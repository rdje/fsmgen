---
id: ial2-ahb-direct-subordinate-pipelined-active-transfer-contract-selection
title: Historical direct AHB D-input completion-dispatch realization was infeasible
answers:
  - "what did IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.5 select?"
  - "what was the historical no-bank direct AHB completion dispatcher?"
  - "why is the .5 direct AHB internal contract superseded?"
date: 2026-07-23
status: superseded
tags: [ahb, subordinate, direct-seed, pipeline, phase, contract, correctness]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'Superseded internal realization|Historical Outcome|register_in|IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.7' docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md
---

`.5` historically selected a direct-seed repair that atomically dispatches a selected active phase
on successful or final-ERROR completion. NONSEQ loads existing addr_q,
write_q, size_q, and wait_ctr and enters ACCESS; SEQ preserves the current
unsupported policy by loading wait_ctr and entering UNSUPPORTED. IDLE, BUSY,
or unselected input enters IDLE without capture.

`.6` superseded that internal realization after emitted HDL proved the existing
register-input names are combinational mux outputs, not old-value-only reads.
Capturing the next read's `HWRITE=0` immediately suppressed the completing
current write. The failed behavior was restored. Current routing belongs to
facts `ial2-ahb-direct-subordinate-completion-capture-substrate-audit` and
`ial2-ahb-direct-subordinate-register-output-completion-contract-selection`;
`.7` selects the Q-named `<-` correction and `.8` later implements it.
