---
id: direct-vhdl-reserved-identifiers
title: Direct VHDL currently emits basic-shaped reserved names without keyword admission
answers:
  - "does direct VHDL reject a signal named OUT?"
  - "why can direct VHDL generation succeed but GHDL reject a reserved identifier?"
  - "why do APB VHDL generic maps reject ACCESS?"
date: 2026-11-01
status: current
tags: [vhdl, identifiers, defects, validation]
evidence: docs/audits/direct-vhdl-reserved-identifier-20261027.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/corpus/direct_rhs_concat_pack.fsm; docs/tasks/PUBLICATION-REGRESSION-REPAIRS.md
reverify: scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --language vhdl --output .artifacts/direct-vhdl-reserved-identifiers.vhd t/corpus/direct_rhs_concat_pack.fsm
---

2026-10-27: direct_rhs_concat_pack reports success with raw OUT, reserved by
shared policy. Basic-shaped names skip keyword checks; rendering admits it.
Authenticated local GHDL 6.0.0 LLVM-JIT rejects OUT; replacing only the source
word with DATA_PORT produces passing analysis. The receipt retains recipes,
source/output identities and exact logs. No elaboration/runtime/general-profile
claim; prior portable VIAL qualification remains separate.

2026-11-01: required T114 aborts on generated ACCESS during generic namespace
admission. Plain APB emits it; exact GHDL rejects it, while replacing only its
declaration/references passes. PUBLICATION-REGRESSION-REPAIRS.18 owns intake;
the blocker triggers ISF-REDUCTION-DELIVERY.22.2 before publication/.6.
Never globally rename tokens: the inventory includes SystemVerilog grammar.
