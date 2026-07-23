---
id: ial2-axi-w-burst4-driver-contract-selection
title: The additive fixed-four AXI W burst driver public contract is selected
answers:
  - "what is the selected fixed-four AXI W driver PPIF contract?"
  - "what are the AXI W burst4 generator and report identities?"
  - "what is the exact fixed-four AXI W driver schedule?"
  - "what does W beat done and beat index mean?"
  - "what artifacts does AxiWBurst4Driver generate?"
  - "what support counts will the AXI W burst4 driver use?"
  - "what must t 1508 prove?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41 select?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.42?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, w, burst4, wlast, driver, contract]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_CONTRACT_SELECTION.md; docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'axi-w-burst4-driver|AxiWBurst4Driver|18 ports|13/6/6/6/6/1/1|306 to 307|PASS handshakes=14|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.42' docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_CONTRACT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41` selects the exact additive
`(axi-w-burst4-driver ...)` public contract. Its generator is
`FSM::IAL2::ProtocolIntent::AxiWBurst4Driver`; parser/result kinds, schema v1,
source/actor/artifacts, support identity, and t/1508 are frozen while shipped
`AxiWDriver` and all write compositions remain unchanged.

The seven-anchor source atomically captures four explicit data32/strobe4
tuples, presents them with continuous WVALID, holds the current tuple under
WREADY stalls, and drives WLAST `0/0/0/1`. Beat done is a level event in every
accepted cycle, including adjacent continuous-ready cycles; beat index
identifies `0/1/2/3`. Final done coincides with index three and clears busy and
WVALID. Busy-time one-shot commands are ignored and reset aborts without
fabricated events.

The exact generated actor has 18 ports, 30 signals, zero states, seven rules at
`13/6/6/6/6/1/1`, seven declared private storage registers, five exact
priorities, one WLAST assertion, one generated ISF, and one generated FSM/HDL
entry. Support targets are 307/348/348. The four-subtest t/1508 generated-HDL
proof must end at `handshakes=14 beat=14 done=3 busy_ignored=1 reset_abort=1`.
`.42` owns the atomic parser/generator/source/support/manifest/test/book/fact
implementation.

Related readiness evidence:
[[ial2-axi-w-burst4-driver-readiness-audit]].
