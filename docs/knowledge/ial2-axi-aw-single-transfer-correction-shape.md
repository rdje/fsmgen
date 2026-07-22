---
id: ial2-axi-aw-single-transfer-correction-shape
title: Priority-resolved ISF rules can restore one AXI AW transfer per command
answers:
  - "how should the AXI AW driver double-handshake be corrected?"
  - "can existing ISF constructs implement an exactly-once Valid-Ready driver?"
  - "does the AXI AW correction need a new ISF construct?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7?"
date: 2026-07-23
status: current
tags: [ial2, axi, initiator, aw, valid-ready, handshake, isf, priority]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_SINGLE_TRANSFER_CORRECTNESS_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; t/1499-ial2-axi-aw-driver.t
reverify: prove -Iperl t/1499-ial2-axi-aw-driver.t
---

The shipped correction uses only existing ISF features: an inline one-cycle
launch handoff, a `launch_aw` rule, an `accept_aw` rule guarded by
`AWVALID && AWREADY`, explicit `accept_aw over launch_aw` priority, and a
transaction loop over latched `active_q`. The checked-in generated schedule has
zero compile issues, passes Verilator lint and Yosys synthesis, preserves
payload through a stall, captures a one-cycle READY pulse, and counts exactly
one acceptance plus one done pulse per command in `t/1499`. Implementation
owner: `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.7`.

Related root-cause fact: [[ial2-axi-aw-driver-double-handshake]].
