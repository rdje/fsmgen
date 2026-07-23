---
id: ial2-ahb-pipelined-active-transfer-contract-selection
title: Generated AHB subordinate uses one accepted next address/control bank
answers:
  - "how will the generated AHB subordinate retain a boundary-free next transfer?"
  - "what is the selected AHB completion-edge phase recapture contract?"
  - "when is the next AHB address phase captured?"
  - "does the AHB phase bank capture HWDATA?"
  - "what happens to an active AHB phase after a final ERROR response?"
  - "is the AHB phase-recapture repair a general outstanding queue?"
  - "which task implements the AHB pipelined active-transfer repair?"
date: 2026-07-23
status: current
tags: [ial2, ahb, subordinate, pipeline, phase, contract, generated-hdl, correctness]
evidence: docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md; docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1519-ial2-ahb-pipelined-active-transfer-audit.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'cycle 37|cycle 48|HWDATA|one_accepted_next_address_control|final cycle of a two-cycle ERROR' docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md
---

The selected generated-subordinate repair captures exactly one next accepted
address/control phase at `HSEL && HREADY && active HTRANS` while the current
transaction drains its generated FSM tail. The audit observed the second bus
acceptance at cycle 37 and `ahb_access_done_q` only at cycle 48, so the delayed
done pulse cannot be the capture event.

The bank contains HADDR, HTRANS, optional HBURST, HWRITE, HSIZE, and
wait_cycles. It does not contain HWDATA, which belongs to the data phase and is
held live while ready is low. Final ERROR plus IDLE cancels the next phase;
final ERROR plus selected active HTRANS captures it for independent later
evaluation after error history clears. `.3` owns the shared generator/report/
runtime repair. The separate direct `.fsm` seed is preserved and audited later
by `.4`. Decision 0020 remains inactive.
