---
id: ial2-axi-manager-initiator-pivot
title: AXI IAL2 pivots from response/bookkeeping to the initiator (bus-driving) side
answers:
  - "does FSMGen's AXI manager drive AXI transactions?"
  - "what is the AXI initiator side / IAL2-AXI-MANAGER-INITIATOR-FRONTIER?"
  - "why did AXI IAL2 pivot from the response side to the initiator side?"
  - "what is the model for an AXI manager initiator in FSMGen?"
  - "what comes after the AXI capacity-status response core?"
date: 2026-07-12
status: current
tags: [ial2, axi, manager, initiator, driver, aw, ar, w, pivot, task-tree]
evidence: docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; ppif/axi_aw_valid_ready.ppif; ppif/axi_aw_w_valid_ready_bundle.ppif; docs/TASK_TREE.md; MEMORY.md
reverify: rg -ncE 'AWVALID|AWADDR|AWLEN|ARVALID|WDATA|WLAST|WSTRB' perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; ls docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

The director directed a pivot of the AXI IAL2 thread from the
**response/bookkeeping** side to the **initiator** (bus-driving) side, owned by
the new active tree `IAL2-AXI-MANAGER-INITIATOR-FRONTIER` (first leaf `.1`:
audit the initiator surface and select the smallest safe first increment).

Current state: the shipped AXI surface can **monitor** a valid-ready handshake
(`ValidReadyChannel.pm`, a 503-line monitor generator → module
`<name>_valid_ready_monitor`) and **track/route** responses
(`AxiManagerCapacityStatus.pm`, ~9,773 lines — a capacity/status + response-demux
+ read-data-capture core that self-labels a `"capacity-status-shell"`), but it
**cannot drive a transaction**: a grep of the capacity/status generator finds 0
mentions of `AWVALID`/`AWADDR`/`AWLEN`/`ARVALID`/`WDATA`/`WLAST`/`WSTRB`.

The initiator side means issuing transactions: driving the AW address channel
(`AWVALID`/`AWADDR`/`AWID`/`AWLEN`/`AWSIZE`/`AWBURST` against `AWREADY`), the W
write-data channel (`WVALID`/`WDATA`/`WSTRB`/`WLAST`), and the AR read-address
channel, with address/burst generation. The direct architectural model is the AHB
requester (`AhbRequester.pm`, 759 lines) — it drives `HTRANS`/`HADDR`/`HBURST`/
`HWDATA` with beat progression and wrap/incr address generation; an AXI initiator
is the same shape over AW/AR/W. The leaning first increment (to confirm in `.1`)
is a bounded AW address-channel driver, mirroring how both the AHB requester and
the AXI response side bootstrapped. This is an AXI profile over the one generic
`.ppif` IAL2 container (decision `0015`), not a new language layer.

The AHB requester BUSY-insertion implementation
`IAL2-FEATURE-COMPLETENESS-FRONTIER.788` remains a durable pending leaf, deferred
by this pivot, not abandoned.
