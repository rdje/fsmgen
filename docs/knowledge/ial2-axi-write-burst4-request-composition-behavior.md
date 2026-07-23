---
id: ial2-axi-write-burst4-request-composition-behavior
title: FSMGen ships the fixed-four AXI AW plus W request composition
answers:
  - "does FSMGen ship a fixed-four AXI write request composition?"
  - "how do I use axi write burst4 request composition ppif?"
  - "when does the AXI write burst4 request done pulse occur?"
  - "what do write beat done and write beat index mean?"
  - "how is the AXI write burst4 4-KiB boundary checked?"
  - "what does t 1509 prove?"
  - "what are the AXI write burst4 request support counts?"
  - "what shipped in IAL2-AXI-MANAGER-INITIATOR-FRONTIER.46?"
date: 2026-07-23
status: current
tags: [ial2, axi, manager, initiator, aw, w, burst4, composition, shipped]
evidence: ppif/axi_write_burst4_request_composition.ppif; perl/FSM/IAL2/ProtocolIntent/AxiWriteBurst4RequestComposition.pm; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1509-ial2-axi-write-burst4-request-composition.t; t/data/axi_write_burst4_request_composition_tb.svt; docs/book/src/16a-ial2-axi.md
reverify: prove -Iperl t/1509-ial2-axi-write-burst4-request-composition.t && ./bin/fsmgen --quiet --strict --check --json ppif/axi_write_burst4_request_composition.ppif && ./bin/fsmgen --verify-hdl ppif/axi_write_burst4_request_composition.ppif
---

`IAL2-AXI-MANAGER-INITIATOR-FRONTIER.46` ships the additive
`(axi-write-burst4-request-composition ...)` source and
`FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition`. One idle command
atomically captures address32, ID4, four explicit data32 values, and four
explicit strobe4 values. It fixes AWLEN three, AWSIZE two, and AWBURST INCR.

Admission requires four-byte alignment and a complete 16-byte span inside one
4-KiB region. The generated guard and concurrent assertion use the audited
renderer-safe predicate: address `0x00000004` and boundary address `0x00000ff0`
are legal, while `0x00001002` is misaligned and `0x00000ff4` crosses 4 KiB.

The flat C4 top reuses the unchanged AW driver and unchanged W-burst4 driver
under one join coordinator. AW and W may complete simultaneously, AW-first, or
W-first. The coordinator remembers their independent completion and emits one
request-only done pulse after AW plus the final W beat; B response acceptance
and transaction success remain separate. The unchanged W child's per-transfer
beat event and two-bit index are exposed directly. Busy commands are ignored,
and reset aborts without a phantom beat or request completion before clean
beat-zero recovery.

The selected top has 29 public signals, three children, 66 nets, 46 declared
links, and 52 resolved links. Its coordinator has 29 ports, 57 signals, zero
states, six rules at `16/2/1/1/5/1`, and five realized priorities. Support
accounting is 308 protocol fixtures and 349 supported/strict-supported fixtures.
The four-subtest t/1509 proves parser/report/static/residue/fail-closed,
support/CLI/artifact/Verilator/Yosys, and assertion-disabled plus
assertion-enabled generated-HDL behavior at exact counts
`AW/W/beat/done=5/18/18/4`, with two illegal commands, one busy ignore, one
reset abort, and recovery.

Selected contract:
[[ial2-axi-write-burst4-request-composition-contract-selection]].
