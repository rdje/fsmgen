---
id: ial2-axi-write-burst4-request-composition-readiness-audit
title: Fixed-four AXI AW plus W request composition is ready for contract selection
answers:
  - "is the fixed-four AXI write request composition ready to implement?"
  - "what syntax is recommended for the AXI write burst4 request composition?"
  - "what is the AXI write burst4 coordinator schedule?"
  - "what are the fixed-four AXI write request C4 counts?"
  - "how is the fixed-four AXI write 4-KiB boundary checked?"
  - "what does fixed-four AXI write request done mean?"
  - "what are IAL2-AXI-MANAGER-INITIATOR-FRONTIER.45 and .46?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, aw, w, burst4, composition, readiness, c4]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_WRITE_REQUEST_COMPOSITION_READINESS_AUDIT.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm
reverify: rg -n '29 interface ports|57 signals|66|PASS aw=5 w=18|renderer-safe' docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_WRITE_REQUEST_COMPOSITION_READINESS_AUDIT.md
---

The additive fixed-four AXI4 manager write-request composition is ready for
exact contract selection. It reuses unchanged AxiAwDriver and
AxiWBurst4Driver children, adds one zero-state six-rule join coordinator, and
selects one flat structural top. One command atomically supplies address32,
ID4, and four explicit data32/strobe4 tuples; AW uses fixed LEN3/SIZE2/INCR.

Admission requires four-byte alignment and a 16-byte span contained within one
4-KiB region. The selected De Morgan predicate was exhaustively checked over
all 4,096 low-address values and renders correctly through the current
concurrent-assertion path. W beat event/index are direct unchanged-child
outputs. Aggregate done joins AW completion with final W completion and does
not include B response retirement.

The real-child scratch candidate has 29 public signals, three children, 66
C4 nets, 46 declared links, and 52 resolved links. Its coordinator has 29
ports, 57 signals, zero states, six rules at `16/2/1/1/5/1`, and five realized
priorities. Strict/semantic/Verilator/Yosys and assertion-disabled plus
assertion-enabled executable proof pass at exact `AW=5`, `W=18`, `beat=18`,
`request-done=4`, with two illegal commands, one ignored busy command, and one
reset abort. `.45` owns contract selection and `.46` atomic implementation.
