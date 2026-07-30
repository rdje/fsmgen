---
id: isf-assert-nested-bitwise-precedence-bug
title: Concurrent assertion inlining can lose nested bitwise parentheses
answers:
  - "why does the AXI fixed-four read assertion reject address 0x00000004?"
  - "is the AXI read burst4 4-KiB admission guard behavior wrong?"
  - "does assertion condition inlining preserve nested bitwise precedence?"
  - "what owns the nested bitwise assertion precedence repair?"
  - "why does the write burst4 request audit use a De Morgan address predicate?"
date: 2026-07-23
status: current
tags: [isf, assertion, systemverilog, precedence, bitwise, axi, verification, pre-existing]
evidence: ppif/axi_read_burst4_transaction_composition.ppif; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; t/1507-ial2-axi-read-burst4-transaction-composition.t; docs/tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md; docs/IAL2_POST_DIRECT_VHDL_REDUCTION_NEXT_OWNER_SELECTION.md
reverify: ./bin/fsmgen --quiet --strict -o .artifacts/sv/fsmgen-axi-read-burst4-assertion-probe.sv ppif/axi_read_burst4_transaction_composition.ppif
---

The shipped AXI fixed-four read admission behavior is correct, but its
generated concurrent boundary assertion is not equivalent for every legal
address. The source places `(| addr[3] addr[2])` inside a long bitwise `&`.
Behavioral rule lowering factors that nested OR into an intermediate and
correctly admits legal four-byte-aligned address `0x00000004`.

The concurrent-property condition is rebuilt by following an intermediate's
driving AST. Its generated SystemVerilog loses the parentheses around the
nested OR, so operator precedence changes the expression from
`high & (bit3 | bit2)` to `(high & bit3) | bit2`. An assertion-enabled
Verilator harness consequently fails on legal address `0x00000004`, even
though the command launches behaviorally. Existing t/1507 addresses cover
`0x0ff0`, ordinary bit2-low legal addresses, misalignment, and `0x0ff4`, but
not a legal address with bit 2 high.

Direct `FSM::CoreAST::BinaryOp->to_systemverilog` rendering of a manually
constructed nested expression preserves parentheses. The remaining audit
owner is therefore the concurrent-check intermediate/inlining path centered
on `GeneratedModuleInfoBuilder::_render_check_condition_sv` and its emitter
consumer, not a blanket claim that every BinaryOp renderer is broken.

Proposed tree `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR` owns the general
root-cause/repair and the missing assertion-enabled AXI regression. The active
fixed-four write-request design is not blocked: it uses an exhaustively
equivalent De Morgan predicate whose generated assertion preserves grouping.

Parent selector `.832` now selects no-behavior audit `.1` as the next bounded
owner. The tree remains proposed until the clean selector commit and separate
continuity activation; no generated behavior changes during selection.
