---
id: sv-intermediate-truthiness-width
title: Scalar reduction origins and render-time intermediate widths
answers:
  - "how does FSMGen render multi-bit intermediate equality to zero?"
  - "why should multi-bit intermediates not render as bare negation?"
  - "why did a high-bit-only vector guard fail?"
  - "what did the .219 renderer-width fix cover?"
  - "how are scalar reduction intermediate origins captured?"
  - "which scalar intermediates allow generic VHDL?"
  - "how are multi-bit generated intermediate signals treated in truthiness?"
  - "why did Core bitwise guard operations become logical?"
  - "why can Core typed literals change value during guard capture?"
  - "why can runtime AST guard text lose comparison grouping?"
  - "how are binary bitwise intermediate operand origins captured?"
date: 2026-10-28
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: >-
  t/2203-whole-bitwise-shapes.t; docs/audits/whole-bitwise-shapes-20261028.json.gz; t/2197-binary-bitwise-intermediate-origins.t; docs/audits/binary-bitwise-intermediate-origins-20261028.json.gz; t/2196-runtime-comparison-grouping.t; docs/audits/runtime-comparison-grouping-20261028.json.gz; perl/FSM/AST/Node.pm; t/2195-core-condition-literal-capture.t; docs/audits/core-condition-literal-capture-20261028.json.gz; t/2194-core-binary-guard-opcodes.t; docs/audits/core-binary-guard-opcodes-20261028.json.gz; perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm; docs/audits/parser-bitwise-intermediate-widths-20261028.json.gz;
  t/2192-parser-bitwise-intermediate-widths.t; t/2190-scalar-intermediate-capture.t; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; docs/audits/direct-vhdl-scalar-intermediates-20261028.json.gz; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; t/208-enable-graph-ast-support.t; t/2191-direct-vhdl-scalar-intermediates.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/219[0124567]*.t t/208-enable-graph-ast-support.t
---

Render-time ASTSupport uses recorded widths: multi-bit zero -> `(~|sum_expr)`;
nonzero keeps sized equality when needed; scalar forms stay compact. The .219 lookup adds no recursive hot-path width inference.

Collector target_intermediates retains actual declarations/text, or {} for absent assigns.
Scalar whole-SignalRef XOR/AND/OR origins bind agreeing defining/runtime ASTs,
fresh selected text, width1 and an actually declared operand (T2190).
Binary &/|/^ origins retain both ordered whole operands, including duplicates,
with the same AST/text/membership proof (T2197). All selected widths remain separate.
Core slices/state/invalid/stored-only/stale/computed/logical operands withhold; compatible
intermediate references retain typed names. Inputs/results detach; empty sets preserve snapshots; no width/type proof.
Paired VHDL proves plain unsigned operands, scalar results and exact assignments
(T2191); other shapes refuse.

Parser bitwise widths use the exact AST width before registration (T2192). Core and emitted widths agree; vector guards test the whole value.

Core binary &/| formerly became logical &&/|| in condition capture (T2194).
Actual operations now survive recursively; native helpers retain vector widths
and whole-value gating. Existing alias/source/unary/caller controls pass.
Typed Core literals formerly lost width/radix through bare value capture, turning
binary value3 into decimal11. Capture now carries Core canonical spelling (T2195);
actual typed/native and parsed guards retain value/width/radix, ordinary unsized
products and caller kinds. The literal audit retains original RED; full .6 stays open.

Runtime comparison text now groups bare &/| children on either side (T2196).
Independent rendered literal outcomes and caller controls pass; typed native HDL
preserves. Broader mixed arithmetic/unary and external qualification remain .6.
