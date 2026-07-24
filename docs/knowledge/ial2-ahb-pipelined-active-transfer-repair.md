---
id: ial2-ahb-pipelined-active-transfer-repair
title: Generated AHB roles preserve one boundary-free accepted address phase
answers:
  - "does the generated AHB family now support consecutive active address phases?"
  - "how does the generated AHB subordinate retain an accepted next phase?"
  - "why does the generated AHB requester retire HTRANS to IDLE after address acceptance?"
  - "how does the generated AHB interconnect retain the data-phase response owner?"
  - "what does the AHB phase_pipeline report mean?"
  - "is the repaired AHB pipeline a general outstanding transaction queue?"
  - "what runtime tests prove the AHB boundary-free phase repair?"
date: 2026-07-23
status: current
tags: [ial2, ahb, subordinate, requester, interconnect, pipeline, phase, generated-hdl, correctness, repair]
evidence: docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1519-ial2-ahb-pipelined-active-transfer-audit.t; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: prove -Iperl t/1519-ial2-ahb-pipelined-active-transfer-audit.t t/1513-ial2-ahb-paired-busy-composition.t t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t
---

Generated AHB roles now preserve one boundary-free accepted address phase as a
coupled protocol pipeline. The subordinate's `ahb_phase_pending_q` bank captures
HADDR, HTRANS, optional HBURST, HWRITE, HSIZE, and wait_cycles at a selected
ready active edge, never HWDATA, and stalls before another acceptance. The
requester separates address and data ownership, retires accepted HTRANS to
IDLE, and captures HRESP/HRDATA on the data-completion edge. The interconnect
retains one one-hot accepted subordinate as response/data owner until completion
and supports same-edge mapped-owner replacement.

t/1519 proves exact two-acceptance/two-completion NONSEQ-to-SEQ behavior and
final-ERROR active-capture versus IDLE-cancel cases. t/1513 and t/1515 preserve
the one- and two-subordinate paired runtime results. This is depth-one protocol
bookkeeping, not a general outstanding queue or transaction-level API. Public
source/support/artifact identities and direct lower-layer `.fsm` seeds remain
unchanged; `.4` audits those seeds separately. Decision 0020 remains inactive.
