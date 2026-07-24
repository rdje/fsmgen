---
id: ial2-ahb-direct-subordinate-completion-capture-substrate-audit
title: Direct AHB register-input completion capture aliases current and next phase state
answers:
  - "why was the direct AHB subordinate no-bank completion dispatcher rejected?"
  - "can direct FSM register_in storage capture the next AHB phase while completing the current phase?"
  - "why did the attempted direct AHB completion repair suppress the current write?"
  - "what lowering constraint applies to the direct AHB subordinate phase repair?"
  - "which task now owns the direct AHB subordinate repair contract?"
  - "is the direct AHB subordinate completion-edge defect repaired now?"
date: 2026-07-23
status: current
tags: [ahb, subordinate, direct-seed, pipeline, phase, lowering, register-in, correctness, audit]
evidence: docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md; docs/IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; fsm/ahb_lite_subordinate.fsm; t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t && rg -n 'Emitted-HDL Root Cause|sampled_write=0|Q-named|UNOPTFLAT|IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.7' docs/IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md
---

The `.5` external exactly-once goal remains valid, but its no-bank internal
realization is infeasible under current direct-FSM lowering. `write_q` is the
output of a combinational register-input mux and is also read by the current
write-completion enable. Capturing the following read's `HWRITE=0` during the
completing write therefore drove `write_q=0` immediately and suppressed the
current storage update; the guarded attempt reported
`sampled_write=0 storage=00000000`.

The failed behavior was fully restored. At `.6` closeout, t/1520 still proved
the then-current seed's completion-edge loss and locked the mux coupling
structurally. `.7` selected Q-named `<-` assignment for the existing four-state
registers, whose generated `*_next` mux provides clean current/next separation without a pending
bank/relaunch. `.8` now ships that implementation. Current behavior routes to
fact `ial2-ahb-direct-subordinate-register-output-completion-repair`; generated
IAL2 behavior plus decision 0020 remain unchanged.
