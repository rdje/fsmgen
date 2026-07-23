---
id: ial2-axi-b-response-acceptor-readiness-audit
title: The explicitly armed bounded AXI B response acceptor is ready for contract selection
answers:
  - "is the AXI B response acceptor ready for contract selection?"
  - "should the first AXI B acceptor be always ready or explicitly armed?"
  - "what widths should the first AXI B response acceptor use?"
  - "what did IAL2-AXI-MANAGER-INITIATOR-FRONTIER.12 conclude?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, b, response, acceptor, readiness, task-tree]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_READINESS_AUDIT.md; docs/IAL2_AXI_MANAGER_INITIATOR_POST_W_NEXT_INCREMENT_SELECTION.md; docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; ppif/axi_manager_capacity_status_response_demux.ppif; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
reverify: rg -n 'explicitly armed|six states|handshakes=2 done_pulses=2|BID.*width 4|BRESP.*width 2|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.12|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.13' docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_READINESS_AUDIT.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.12` finds the bounded AXI manager B
write-response-channel acceptor ready for public-contract selection.

The safe first slice is explicitly armed for one response, not continuously
ready. One idle-time arm causes manager-owned `BREADY` to assert independently
of subordinate-owned `BVALID`; one `BVALID && BREADY` edge captures fixed
4-bit `BID` and 2-bit `BRESP`, clears ready/busy, holds the captured response,
and yields one later one-cycle done pulse. This prevents unowned acceptance and
avoids requiring a response queue for back-to-back transfers.

A temporary existing-ISF probe strict-checked and lowered with six states,
zero compile issues, and three accept-over-arm priority resolutions. Generated
HDL executed two scenarios—already-high/held-high BVALID and four-cycle delayed
BVALID—with `PASS handshakes=2 done_pulses=2 bid=9 bresp=3` and final
ready/busy low.

`.13` must select exact public syntax, generator/result/schema/source/module/
support/test identities, report/residue, diagnostics, and the following
implementation leaf. AW/W/B coordination, capacity integration, outstanding/
back-to-back responses, width/sideband extensions, AR/R, transaction-interface
activation, aliases, verification output, direct/backend variants/VHDL, and
AHB/APB remain deferred.
