---
id: isf-assert-nested-bitwise-precedence-bug
title: Concurrent assertion inlining can lose nested bitwise parentheses
answers:
  - "why does the AXI fixed-four read assertion reject address 0x00000004?"
  - "is the AXI read burst4 4-KiB admission guard behavior wrong?"
  - "does assertion condition inlining preserve nested bitwise precedence?"
  - "what owns the nested bitwise assertion precedence repair?"
  - "why does the write burst4 request audit use a De Morgan address predicate?"
  - "what is the selected repair for inline assertion expression precedence?"
  - "are mixed legacy and CoreAST nodes responsible for the AXI assertion bug?"
date: 2026-07-30
status: current
tags: [isf, assertion, systemverilog, precedence, bitwise, axi, verification, pre-existing]
evidence: ppif/axi_read_burst4_transaction_composition.ppif; perl/FSM/CoreAST.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; t/1507-ial2-axi-read-burst4-transaction-composition.t; t/1544-isf-assert-nested-bitwise-precedence-readiness.t; docs/ISF_ASSERT_NESTED_BITWISE_PRECEDENCE_READINESS_AUDIT.md; docs/tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md; docs/IAL2_POST_DIRECT_VHDL_REDUCTION_NEXT_OWNER_SELECTION.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- env TMPDIR=.artifacts/tmp/tests prove -v t/1544-isf-assert-nested-bitwise-precedence-readiness.t
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
constructed nested expression preserves parentheses. A recursive trace of the
generated coordinator proves that the relevant property tree and every
expression beneath it use `FSM::CoreAST`; no mixed legacy `FSM::AST` node is
involved. The exact loss occurs when
`GeneratedModuleInfoBuilder::_render_check_condition_sv` replaces an
inlineable `SignalRef` with a standalone rendered driving-AST string. The
standalone nested OR correctly has no outer parentheses, but its original
child-parent precedence context is then gone when that string is concatenated
into the parent AND.

Audit `.1` selects a general substitution-boundary repair: every successfully
rendered inline-intermediate replacement must remain one explicitly grouped
SystemVerilog expression. This is the textual equivalent of substituting one
AST node at the `SignalRef` position, covers all parent/child operator pairs,
and leaves the canonical CoreAST renderer, behavioral lowering, property
operators, cycle fallback, and emitter unchanged. Operator-pair special cases,
global precedence plumbing, disabling inlining, and an AXI source rewrite are
rejected as narrower or larger than the proven owner.

Active tree `ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR` owns the general
root-cause/repair and the missing assertion-enabled AXI regression. Tracked
t1544 now deterministically characterizes the correct direct CoreAST output,
the inline-intermediate property shape, correct factored behavior, and current
malformed concurrent property. Implementation `.2` must reconcile that test,
add direct/inlined t1411 and property-wrapper t1412 coverage, preserve the
t1410 carrier, and run t1507 with assertions enabled plus legal address
`0x00000004`. The fixed-four write-request design remains unaffected: it uses
an exhaustively equivalent De Morgan predicate whose generated assertion
preserves grouping.

Audit `.1` changes no generated behavior. Its selected implementation requires
a clean separate activation commit before product or existing-test behavior
may change.
