---
id: sv-intermediate-truthiness-width
title: Scalar origins and intermediate widths
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
  - "how are source-helper trees expanded into original width leaves?"
  - "why does an unsized literal in a source bitwise helper refuse generation?"
  - "why does large PPIF generation repeatedly revalidate unrelated source trees?"
  - "why can generated HDL differ only in its Date header?"
date: 2026-11-01
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: >-
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/SourceBitwiseTreeWidthSupport.pm; docs/audits/source-bitwise-event-publisher-20261029.json.gz; docs/audits/push-readiness-20261025/allocation_scalar_conservation_read_20261101.py;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/230[01]*.t t/221[5-9]*.t t/219[0124567]*.t t/208-*.t t/2208*.t t/2210*.t t/223[356789]*.t t/224[0-9]*.t
---

Prior proof: `docs/audits/width-card-evidence-20261028.json.gz`, `original_cards[card path]`; verify UTF-8 `source` SHA256.

ASTSupport: zero `(~|sum_expr)`, nonzero reduction, exact ==1; compact fixed scalars. No symbolic folding or recursive inference (.219).

target_intermediates: text, unassigned {}. Origins need defining/runtime/cache agreement and fresh text/declarations: whole-ref reductions width1 (T2190); binary &/|/^ ordered/duplicate slots, independent selected widths (T2197).
Sliced/state/invalid/stored-only/stale/computed/logical Core withhold. Compatible typed names, detached/empty snapshot shape preserve; no origin width/type proof.
width_allocation: intrinsic max/ordered origin/plain widths; publication rechecks policy/origin/text/plain sources; frozen emission re-proves targets/events.
T2191 VHDL: plain unsigned operands/scalar result/exact assignment; others refuse.

T2192: exact pre-registration bitwise AST sizing matches Core/HDL; whole-vector guards.
T2194: Core &/| from &&/||; nested/vector/whole guards, aliases/unary/callers preserve. T2195: value/width/radix, typed/native/parsed/unsized/caller kinds preserve; binary3->decimal11 bug RED retained in literal audit.
T2196: bare &/| group either comparison side; literal/caller/typed native HDL preserve.

Arithmetic stays inline. Whole/computed factorizer births + canonical leaves + final target/ledger proof emit generic ranges (direct-declared-width-consumers); comparisons/! scalar, opaque constraints block policy.
SourceBitwiseTreePolicySupport bounds closed ordered tree/origin/max. Explicit Core root/tree/all-leaf intent binds detached weak lifetime IDs/max/revisions; matching writes revoke; final capture rejects late writes.
source_tree_events: fresh trees, exact reference/role/metadata refresh only. Parser/facade/backend/selected targets bind current policy; binary events two-slot; negated n-ary wraps helper in scalar logical !. Direct widths: frozen leaves T2243; leaf intent T2244; recursive Core tree/binary edges/repeats/bounds/child/raw fences T2245; independent child targets/currentness T2246; computed binary T2247; ranges/guards/generation fence T2248. Full .6 pending.
T2269: former unsized Core1/SV32 refusal joins literal source/final declaration proof; Core widths preserve.

Cost .20.2: nonmember/no-op selection; full writes/currentness. PPIF case native0; Date=ScaffoldEmitter localtime. Reader above --self-test.
