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
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/AST/Node.pm; perl/FSM/IntermediateWidthAllocationSupport.pm; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm; docs/audits/width-card-evidence-20261028.json.gz;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/219[0124567]*.t t/208-enable-graph-ast-support.t t/2208-binary-allocation-event-contract.t t/2210-binary-allocation-event-publication.t
---

Component owners above are current evidence. The complete original card/proof inventory (baseline and digests) is retained in `docs/audits/width-card-evidence-20261028.json.gz`; recover its exact source:

`python3 -B -c 'import gzip,json,hashlib; r=json.load(gzip.open("docs/audits/width-card-evidence-20261028.json.gz")); c=r["original_cards"]["docs/knowledge/sv-intermediate-truthiness-width.md"]; b=c["source"].encode(); assert hashlib.sha256(b).hexdigest()==c["sha256"]; print(b.decode(),end="")'`.

Render-time ASTSupport uses recorded widths: multi-bit zero -> `(~|sum_expr)`;
nonzero keeps sized equality when needed; scalar forms stay compact. The .219 lookup adds no recursive hot-path width inference.

Collector target_intermediates retains actual declarations/text, or {} for absent assigns.
Scalar whole-SignalRef XOR/AND/OR origins bind agreeing defining/runtime ASTs,
fresh selected text, width1 and an actually declared operand (T2190).
Binary &/|/^ origins retain both ordered whole operands, including duplicates,
with the same AST/text/membership proof (T2197). All selected widths remain separate.
Core slices/state/invalid/stored-only/stale/computed/logical operands withhold; compatible
intermediate references retain typed names. Inputs/results detach; empty sets preserve snapshots; origins prove no width/type relation. Optional width_allocation checks a closed intrinsic-max policy against the ordered origin/plain actual declaration widths; Actual publication rechecks current attached policy, fresh origin/text and plain sources; symbolic emission stays pending.
Paired VHDL proves plain unsigned operands, scalar results and exact assignments
(T2191); other shapes refuse.

Parser bitwise widths use the exact AST width before registration (T2192). Core and emitted widths agree; vector guards test the whole value.

Core binary &/| formerly became logical &&/|| in condition capture (T2194); nested operators, vector helpers and whole-value gating now preserve.
Alias/source/unary/caller controls pass. Bare value capture lost width/radix, changing binary value3 to decimal11; Core canonical spelling now preserves both (T2195).
Actual typed/native and parsed guards retain value/width/radix, ordinary unsized products and caller kinds. The literal audit retains original RED; full .6 stays open.

Runtime comparison text now groups bare &/| children on either side (T2196).
Independent rendered literal outcomes and caller controls pass; typed native HDL
preserves. Broader mixed arithmetic/unary and external qualification remain .6.
