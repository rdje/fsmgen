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
  - "why do source-owned n-ary bitwise helpers remain numeric?"
  - "what validates source bitwise tree allocation data?"
date: 2026-10-29
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: >-
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/SourceBitwiseTreeWidthSupport.pm; docs/audits/source-bitwise-journal-20261029.json.gz;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/221[56789]*.t t/219[0124567]*.t t/208-enable-graph-ast-support.t t/2208-binary-allocation-event-contract.t t/2210-binary-allocation-event-publication.t t/223[35]*.t t/2236-source-bitwise-tree-policy.t t/2237-source-bitwise-tree-core-holder.t t/2238*.t
---

Original cards/proofs with baseline/digests: `docs/audits/width-card-evidence-20261028.json.gz`; recover:

`python3 -B -c 'import gzip,json,hashlib; r=json.load(gzip.open("docs/audits/width-card-evidence-20261028.json.gz")); c=r["original_cards"]["docs/knowledge/sv-intermediate-truthiness-width.md"]; b=c["source"].encode(); assert hashlib.sha256(b).hexdigest()==c["sha256"]; print(b.decode(),end="")'`.

ASTSupport: zero -> `(~|sum_expr)`; nonzero reduces; ==1 stays equality; fixed scalars stay compact. Symbolic widths never set folds; .219 adds no recursive inference.

target_intermediates keeps selected text or {} without assignment.
Origins require agreeing defining/runtime/cached ASTs, fresh text and declared operands:
whole-SignalRef reductions are width1 (T2190); binary &/|/^ keeps ordered slots/duplicates and separate selected widths (T2197).
Core slices/state/invalid/stored-only/stale/computed/logical withhold; compatible references keep typed names.
Inputs/results detach, empty sets preserve snapshots; origins prove no width/type relationship.
Closed width_allocation proves intrinsic max/ordered origin/plain widths; publication rechecks current policy/origin/text/plain sources. Frozen ranges emit with final target/event reproof.
Paired VHDL requires plain unsigned operands, scalar results and exact assignments (T2191); other shapes refuse.

T2192 sizes from exact AST before bitwise registration; Core/HDL agree, vector guards test whole values.

T2194 preserves Core &/| (formerly &&/||), nested/vector/whole guards and aliases/unary/callers. T2195 preserves Core literal value/width/radix, typed/native/parsed/unsized products and caller kinds; binary3 formerly became decimal11; literal audit retains RED.

T2196 groups bare &/| on either comparison side, preserving literals/callers and typed native HDL. Source n-ary/full .6 stay open.

Arithmetic stays inline in Parser. Proved whole/computed factorizer births, canonical leaf relations and final target/ledger checks now emit generic ranges;
see direct-declared-width-consumers. Comparisons/! stay scalar; opaque constraints withhold policy. SourceBitwiseTreePolicySupport: closed ordered tree data under shared walk bounds. SourceBitwiseTreeWidthSupport binds explicit Core root/tree/all leaves to detached weak lifetime IDs/max/revisions; matching writes revoke; final recheck rejects late writes. Parser now stages source_tree_events and refreshes only exact reference/role/metadata writes. Completed publication/target/range remain pending. Binary events require two whole operands. Negated forms wrap that helper in scalar logical !.
