---
id: direct-vhdl-reserved-identifiers
title: Direct VHDL currently emits basic-shaped reserved names without keyword admission
answers:
  - "does direct VHDL reject a signal named OUT?"
  - "why can direct VHDL generation succeed but GHDL reject a reserved identifier?"
date: 2026-10-27
status: current
tags: [vhdl, identifiers, defects, validation]
evidence: docs/audits/direct-vhdl-reserved-identifier-20261027.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/corpus/direct_rhs_concat_pack.fsm
reverify: scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --language vhdl --output .artifacts/direct-vhdl-reserved-identifiers.vhd t/corpus/direct_rhs_concat_pack.fsm
---

The native CLI reports success for direct_rhs_concat_pack but emits the raw
signal name OUT. The shared VHDL identifier policy marks OUT reserved. The
normalizer skips basic-shaped identifiers before checking keywords; the
renderer has no subsequent keyword admission for this declaration.

Authenticated repository-local GHDL 6.0.0 LLVM-JIT rejects the newly emitted
artifact at that declaration. Replacing only the source word OUT with
DATA_PORT yields a newly emitted artifact that passes analysis. Recipes,
source/output identities and exact analysis logs survive in the receipt.
No elaboration, runtime or general direct profile qualification is claimed.
The earlier exact portable VIAL fixture qualification is separately scoped.

ISF-REDUCTION-DELIVERY.22.2 owns the P1 repair before .6 qualification; activate
earlier only if required integration demonstrates a blocker. Do not rename
all keyword lexemes: the inventory also includes SystemVerilog grammar.
