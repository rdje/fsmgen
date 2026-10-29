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
  - "how are source-helper trees expanded into original width leaves?"
  - "why does an unsized literal in a source bitwise helper refuse generation?"
date: 2026-10-29
status: current
tags: [systemverilog, hdl, ast, width, intermediate-signal, codegen]
evidence: >-
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Synthesis/EnableGraph/ASTSupport.pm; perl/FSM/SourceBitwiseTreeWidthSupport.pm; docs/audits/source-bitwise-event-publisher-20261029.json.gz;
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/221[5-9]*.t t/219[0124567]*.t t/208-*.t t/2208*.t t/2210*.t t/223[356789]*.t t/224[0-9]*.t
---

Original card/proofs: `docs/audits/width-card-evidence-20261028.json.gz`; recover:

`python3 -B -c 'import gzip,json,hashlib; r=json.load(gzip.open("docs/audits/width-card-evidence-20261028.json.gz")); c=r["original_cards"]["docs/knowledge/sv-intermediate-truthiness-width.md"]; b=c["source"].encode(); assert hashlib.sha256(b).hexdigest()==c["sha256"]; print(b.decode(),end="")'`.

ASTSupport: zero `(~|sum_expr)`; nonzero reduction; ==1 exact; fixed scalars compact. Symbolic widths cannot fold; .219 adds no recursive inference.

target_intermediates: text; {} without assignment. Origins require defining/runtime/cache agreement, fresh text/declarations: whole-ref reductions width1 (T2190); binary &/|/^ ordered/duplicate slots and independent selected widths (T2197).
Sliced/state/invalid/stored-only/stale/computed/logical Core withhold; compatible typed names preserve. Detached data; empty snapshot shape preserves; no origin width/type proof.
width_allocation: intrinsic max/ordered origin/plain widths; publication rechecks policy/origin/text/plain sources; frozen emission re-proves final targets/events.
T2191 VHDL: plain unsigned operands/scalar result/exact assignment; others refuse.

T2192: exact pre-registration bitwise AST sizing; Core/HDL agree; whole-vector guards.
T2194: Core &/| (from &&/||), nested/vector/whole guards, aliases/unary/callers preserve. T2195: literal value/width/radix, typed/native/parsed/unsized/caller kinds preserve; binary3->decimal11 was faulty; literal audit retains RED.
T2196: bare &/| group either comparison side; literal/caller/typed native HDL preserve.

Parser arithmetic stays inline; whole/computed factorizer births, canonical leaves and final target/ledger proof emit generic ranges (direct-declared-width-consumers). Comparisons/! scalar; opaque constraints block policy.
SourceBitwiseTreePolicySupport bounds closed ordered tree/origin/max. Explicit Core root/tree/all-leaf intent binds detached weak lifetime IDs/max/revisions; matching writes revoke; final capture rejects late writes.
Parser source_tree_events: fresh trees; only exact reference/role/metadata refresh. Parser/facade/backend/selected targets bind current policy; binary events stay two-slot; negated n-ary wraps that helper in scalar logical !. Direct widths: frozen leaves T2243; leaf intent T2244; recursive Core tree/binary edges/repeats/bounds/child/raw fences T2245; independent child targets/currentness T2246; computed binary T2247; ranges/guards/generation fence T2248. Full .6 pending.
Unsized literal3: Core placeholder1/SV32 width check refuses; repair ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.4.1.
