---
id: ial2-ahb-pipelined-active-transfer-runtime-audit
title: Generated AHB subordinate drops a boundary-free accepted SEQ phase
answers:
  - "does the generated AHB subordinate accept consecutive NONSEQ and SEQ address phases?"
  - "what happens when an AHB SEQ phase follows NONSEQ without IDLE or BUSY?"
  - "is the AHB boundary-free active-transfer defect runtime proven?"
  - "why does ahb_access_active_q drop a new AHB transfer?"
  - "can the AHB subordinate require an IDLE boundary without deadlocking?"
  - "which task owns the AHB completion-boundary phase recapture repair?"
date: 2026-07-23
status: current
tags: [ial2, ahb, subordinate, pipeline, phase, generated-hdl, correctness, bug, audit]
evidence: docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1519-ial2-ahb-pipelined-active-transfer-audit.t; t/data/ahb_pipelined_active_transfer_audit_tb.svt; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1519-ial2-ahb-pipelined-active-transfer-audit.t
---

Generated-HDL t/1519 presents a distinct `SEQ` byte write immediately after a
`NONSEQ` byte write and holds it through the first transfer's ready-low data
phase. The bus accepts two active address phases, but the current subordinate
records one admission/completion, retains captured address 0/`NONSEQ`, and
leaves storage at `0x00000011` instead of applying the second lane-one write to
produce `0x00002211`.

`ahb_access_active_q` prevents duplicate admission of a held transfer but
releases only on unselected/IDLE/BUSY. Requiring such a boundary cannot safely
fail closed: keeping ready low deadlocks the held next phase, while raising
ready accepts it. Audit `.1` therefore selects explicit atomic
completion-boundary phase recapture/tracking for no-behavior contract
selection in `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.2`. Decision 0020 and
the protocol-neutral transaction-layer horizon remain inactive.
