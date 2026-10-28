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
  - "where are arithmetic intermediate helpers allocated?"
  - "why do arithmetic helpers lack generic ranges?"
date: 2026-10-28
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: >-
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/AST/Node.pm; perl/FSM/IntermediateWidthAllocationSupport.pm; perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm; docs/audits/arithmetic-range-emission-20261028.json.gz;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/221[56789]*.t t/219[0124567]*.t t/208-enable-graph-ast-support.t t/2208-binary-allocation-event-contract.t t/2210-binary-allocation-event-publication.t
---

Component owners above are current evidence. The complete original card/proof inventory (baseline and digests) is retained in `docs/audits/width-card-evidence-20261028.json.gz`; recover its exact source:

`python3 -B -c 'import gzip,json,hashlib; r=json.load(gzip.open("docs/audits/width-card-evidence-20261028.json.gz")); c=r["original_cards"]["docs/knowledge/sv-intermediate-truthiness-width.md"]; b=c["source"].encode(); assert hashlib.sha256(b).hexdigest()==c["sha256"]; print(b.decode(),end="")'`.

ASTSupport uses fixed widths/symbolic ranges: zero -> `(~|sum_expr)`;
nonzero reduces, equals-one stays equality, fixed scalars stay compact. Symbolic widths are not fold sizes; .219 adds no recursive inference.

Collector target_intermediates keeps selected text, or {} without an assign.
Origins require agreeing defining/runtime/cached ASTs, fresh text and declared operands:
whole-SignalRef reductions are width1 (T2190); binary &/|/^ keeps ordered slots/duplicates and separate selected widths (T2197).
Core slices/state/invalid/stored-only/stale/computed/logical operands withhold; compatible intermediate references keep typed names.
Inputs/results detach, empty sets preserve snapshots; origins prove no width/type relationship.
Closed width_allocation additionally proves intrinsic max/ordered origin/plain widths; publication rechecks current policy, fresh origin/text and plain sources; matched frozen ranges emit with final target/event reproof.
Paired VHDL requires plain unsigned operands, scalar results and exact assignments (T2191); other shapes refuse.

Parser bitwise widths use the exact AST width before registration (T2192). Core and emitted widths agree; vector guards test the whole value.

Capture preserves Core bitwise &/| (formerly &&/||), nested/vector/whole-value guards (T2194), aliases/unary/caller controls.
Core canonical literals preserve value/width/radix, typed/native/parsed/unsized products and caller kinds (T2195); binary value3 formerly became decimal11. Original RED stays in the literal audit.

Runtime comparisons group bare &/| on either side (T2196); independent literal/caller controls and typed native HDL preserve. Mixed arithmetic/unary and external qualification remain .6.

Arithmetic stays inline in Parser; factorizer births/intrinsic-max policies bind whole operands.
Arithmetic origins/policies/ranges emit with final reproof. Comparisons/! scalar; opaque constraints withhold policy.
