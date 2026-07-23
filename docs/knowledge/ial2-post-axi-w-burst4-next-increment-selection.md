---
id: ial2-post-axi-w-burst4-next-increment-selection
title: The next AXI initiator increment is a fixed-four AW plus W request composition
answers:
  - "what comes after the shipped AXI W burst4 driver?"
  - "is a fixed-four AXI write request composition selected next?"
  - "will the next AXI write burst slice include B response completion?"
  - "can the fixed-four AXI write request reuse the existing AW driver?"
  - "what does fixed-four AXI write request done mean?"
  - "does the next AXI initiator slice activate decision 0020?"
  - "what is IAL2-AXI-MANAGER-INITIATOR-FRONTIER.44?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, aw, w, burst4, composition, selection]
evidence: docs/IAL2_AXI_MANAGER_INITIATOR_POST_W_BURST4_NEXT_INCREMENT_SELECTION.md; docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/AxiAwDriver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWBurst4Driver.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteRequestComposition.pm; perl/FSM/IAL2/ProtocolIntent/AxiWriteTransactionComposition.pm
reverify: rg -n 'fixed-four AW\+W write-request composition|IAL2-AXI-MANAGER-INITIATOR-FRONTIER\.44|request completion only|AxiWBurst4Driver' docs/IAL2_AXI_MANAGER_INITIATOR_POST_W_BURST4_NEXT_INCREMENT_SELECTION.md docs/tasks/IAL2-AXI-MANAGER-INITIATOR-FRONTIER.md
---

After the additive fixed-four W burst driver shipped, the next smallest
coherent AXI manager initiator increment is a fixed-four AW+W write-request
composition. The leading boundary reuses unchanged `AxiAwDriver` and
unchanged `AxiWBurst4Driver`, adds one generated join coordinator, and selects
one flat structural top. It fixes AWLEN3/AWSIZE2/AWBURST-INCR and requires a
four-byte-aligned 16-byte span contained within one 4-KiB region.

One aggregate command atomically supplies address32, ID4, and four explicit
data32/strobe4 tuples. AW and W may complete in either order. Request done
means both the single AW transfer and the fourth/final W transfer completed;
it does not mean a B response was accepted. Fixed-four AW+W+B full-transaction
completion is deliberately deferred until this request boundary is proven.

`.44` owns the behavior-neutral readiness audit for exact syntax, bindings,
legality predicate, coordinator schedule, flat-top topology, artifacts,
reports, diagnostics, accounting, CLI/HDL proof, and following contract plus
implementation leaves. Dynamic/general payloads, capacity integration,
outstanding queues, aliases, and decision 0020 remain deferred.
