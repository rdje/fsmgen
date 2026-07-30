---
id: ial2-post-direct-vhdl-reduction-next-owner-selection
title: Nested bitwise assertion precedence audit follows direct VHDL reduction repair
answers:
  - "what follows direct VHDL reduction-expression lowering?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.832 select?"
  - "why is the nested bitwise assertion precedence audit selected next?"
  - "why does AXI fixed-four read reject address 0x00000004 with assertions enabled?"
  - "does t1507 currently run with assertions enabled?"
  - "does selecting the assertion audit activate HIAL or VIAL?"
date: 2026-07-30
status: current
tags: [ial2, selector, isf, assertion, systemverilog, precedence, axi, verification]
evidence: docs/IAL2_POST_DIRECT_VHDL_REDUCTION_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md; docs/knowledge/isf-assert-nested-bitwise-precedence-bug.md; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; ppif/axi_read_burst4_transaction_composition.ppif; t/1410-isf-assert-carrier.t; t/1411-isf-assert-emit.t; t/1412-isf-property-implication.t; t/1507-ial2-axi-read-burst4-transaction-composition.t
reverify: prove -Iperl t/1410-isf-assert-carrier.t t/1411-isf-assert-emit.t t/1412-isf-property-implication.t t/1507-ial2-axi-read-burst4-transaction-composition.t; ./bin/fsmgen --quiet --strict -o .artifacts/tmp/tests/axi-read-burst4-assertion-probe.sv ppif/axi_read_burst4_transaction_composition.ppif; rm -f .artifacts/tmp/tests/axi-read-burst4-assertion-probe.sv
---

Parent selector `.832` selects proposed no-behavior audit
`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1` after direct-VHDL reduction
lowering ships cleanly.

The fixed-four AXI read behavioral guard correctly factors
`high & (bit3 | bit2)` through an intermediate, but the generated concurrent
assertion inlines it as `high & bit3 | bit2`. SystemVerilog precedence changes
the meaning, so legal address `0x00000004` launches behaviorally and then fails
the assertion. Current t1507 passes only because its Verilator runtime uses
`--no-assert`; t1410-t1412 and t1507 pass 4 files/21 tests but do not cover the
legal-bit-2 assertion case.

The selected audit traces the CoreAST/intermediate-inlining path, freezes a
general AST-preserving contract, and defines assertion-enabled coverage before
implementation `.2`. It changes no behavior. HIAL/VIAL, end-to-end scale,
startup alignment, other protocols/backends, simulator profiles, and decision
`0020` remain independently proposed or deferred.

Clean selector commit `1be57f7bd` activates only audit `.1` through
continuity changes. The malformed property and every shipped behavior remain
unchanged during activation.
