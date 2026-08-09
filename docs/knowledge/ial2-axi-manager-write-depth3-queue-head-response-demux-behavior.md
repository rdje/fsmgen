---
id: ial2-axi-manager-write-depth3-queue-head-response-demux-behavior
title: Write depth-3 response-demux width correctness
answers:
  - "is write depth-3 queue-head response-demux generated?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.171 ship?"
  - "what does ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif cover?"
  - "what support-accounting entry covers write depth-3 queue-head response-demux?"
  - "why did a multi-bit factored intermediate become !x or bare x?"
  - "how was the AXI queue-head WIDTHTRUNC truthiness bug fixed?"
date: 2026-08-10
status: current
tags: [ial2, axi, manager, response-demux, queue-head, width, truthiness, verilator]
evidence: ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/HDL/ASTFactorization.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm; t/208-enable-graph-ast-support.t; t/220-systemverilog-intermediate-signal-width-support.t; t/225-systemverilog-consolidated-intermediate-normalization-support.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-T1436-PREEXISTING-FAILURES.md
reverify: env TMPDIR=.artifacts/tmp/tests prove -Iperl t/208-enable-graph-ast-support.t t/220-systemverilog-intermediate-signal-width-support.t t/225-systemverilog-consolidated-intermediate-normalization-support.t; env TMPDIR=.artifacts/tmp/tests ./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.171` shipped generated write depth-3
concrete same-ID queue-head response-demux: `w0`, `w1`, and `w2` share `BID`
`3` with queue depth `3`.

The public sample is `ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif`.
Its `generated_write_bid_queue_head_demux` boundary reports three completion
outputs, three demux rules, four demux assertions, nine queue-slot signals, 54
queue updates, and 14 queue assertions.

Generic AST factorization has no module-width context. A new intermediate is
therefore `unresolved_factorization_ast` until the SystemVerilog backend infers
and publishes its width before rendering. Only an authoritative one-bit value
may collapse `x == 0`/`x == 1` to `!x`/bare `x`; unknown width fails closed,
multibit zero uses a reduction, and multibit one stays an explicit equality.
The multi-group queue-head reproducer and representative read/write mixed-depth
variants now pass Verilator and Yosys.
