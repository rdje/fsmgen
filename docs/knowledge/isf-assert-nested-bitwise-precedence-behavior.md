---
id: isf-assert-nested-bitwise-precedence-behavior
title: Concurrent checks preserve grouped inline-intermediate expressions
answers:
  - "does FSMGEN currently preserve nested bitwise precedence in assertions?"
  - "how are inline intermediate expressions grouped in generated properties?"
  - "does AXI fixed-four read address 0x00000004 pass generated assertions?"
  - "why does t1507 use separate behavior and all-assertion harnesses?"
  - "what shipped the nested-bitwise assertion precedence repair?"
date: 2026-07-30
status: current
tags: [isf, assertion, systemverilog, precedence, bitwise, axi, verification, behavior]
evidence: perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; t/1410-isf-assert-carrier.t; t/1411-isf-assert-emit.t; t/1412-isf-property-implication.t; t/1507-ial2-axi-read-burst4-transaction-composition.t; t/1544-isf-assert-nested-bitwise-precedence-readiness.t; t/data/axi_read_burst4_transaction_composition_tb.svt; t/data/axi_read_burst4_transaction_assertion_tb.svt; docs/ISF_ASSERT_NESTED_BITWISE_PRECEDENCE_BEHAVIOR.md; docs/tasks/ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.md
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- env TMPDIR=.artifacts/tmp/tests prove t/1410-isf-assert-carrier.t t/1411-isf-assert-emit.t t/1412-isf-property-implication.t t/1507-ial2-axi-read-burst4-transaction-composition.t t/1544-isf-assert-nested-bitwise-precedence-readiness.t
---

Concurrent-check rendering now keeps every successfully substituted compiler
intermediate inside one explicit pair of SystemVerilog parentheses. A driving
expression rendered without parent precedence therefore remains one AST-sized
operand when inserted into the caller. Direct CoreAST rendering is unchanged.

Nested source such as `(& high (| bit3 bit2))` consequently renders with the
semantic core `high & (bit3 | bit2)`, including as a leaf of overlapping
implication and formal-only `next`/`within` wrappers. The historical malformed
`high & bit3 | bit2` substitution is absent.

The public AXI fixed-four read behavioral guard is unchanged. Its generated
assertion now agrees for legal address `0x00000004`. The expanded behavior
harness proves two illegal rejections plus exact `5/17/5/17/4`
AR/R/request/beat/transaction counts with assertions disabled because those
negative commands intentionally violate the boundary assertion. A separate
all-assertion legal-only harness proves address `0x00000004`, fixed
LEN3/SIZE2/INCR metadata, correct RID/RLAST, four clean beats, and exact
`1/4/1/4/1` completion.

The repair changes no public syntax, AXI admission, property operator,
formal-only classification, report/semantic/MCP schema, support accounting,
backend contract, HIAL/VIAL architecture, or simulator qualification. The
Verilator runtime proves only the supported generated subset, not full
SystemVerilog/UVM coverage.

Clean behavior commit `80aa203ab` hands continuity to no-behavior parent
selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.833`; no broader roadmap owner is
implicitly active while that selector compares the remaining directions.
Completed `.833` selects no-behavior
`MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1`; assertion behavior remains complete
and unchanged while that separate documentation leaf waits for activation.
