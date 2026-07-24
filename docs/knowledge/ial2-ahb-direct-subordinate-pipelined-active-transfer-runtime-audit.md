---
id: ial2-ahb-direct-subordinate-pipelined-active-transfer-runtime-audit
title: Before .8 the direct AHB subordinate dropped completion-edge active phases
answers:
  - "what did IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4 prove?"
  - "did the direct AHB subordinate drop completion-edge phases before .8?"
  - "what was the historical direct AHB final-ERROR continuation defect?"
date: 2026-07-23
status: historical
tags: [ahb, subordinate, direct-seed, pipeline, phase, generated-hdl, correctness, bug, audit]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; t/data/ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
---

Before `.8`, the direct lower-layer `fsm/ahb_lite_subordinate.fsm` sampled
address/control only in `IDLE`. t/1520 proves that successful `ACCESS` and
final `ERROR_COMPLETE` ready edges each accept a held selected active phase at
the bus but return to IDLE without capturing it.

The success case records two bus acceptances, one internal capture/completion,
no error, and only the first write value `0x11111111`. The final-ERROR case
records two acceptances, one capture/completion, exactly two ERROR cycles, and
zero storage. This direct seed is separate from the generated IAL2 family
repaired by `.3`. `.6` later proved the `.5` existing-register realization
unsafe under register-input mux lowering and restored the failed attempt. `.7`
selected a Q-named `<-` four-state dispatcher without a pending bank/relaunch,
and `.8` now implements it. Current behavior routes to fact
`ial2-ahb-direct-subordinate-register-output-completion-repair`. Decision 0020
remains inactive.
