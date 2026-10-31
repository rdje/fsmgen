---
id: direct-vhdl-reserved-identifiers
title: Direct VHDL maps declared reserved names and preserves source identities
answers:
  - "does direct VHDL reject a signal named OUT?"
  - "why can direct VHDL generation succeed but GHDL reject a reserved identifier?"
  - "why do APB VHDL generic maps reject ACCESS?"
date: 2026-11-01
status: current
tags: [vhdl, identifiers, validation]
evidence: docs/audits/direct-vhdl-reserved-identifier-20261027.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; t/corpus/direct_rhs_concat_pack.fsm; docs/tasks/PUBLICATION-REGRESSION-REPAIRS.md
reverify: scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --language vhdl --output .artifacts/direct-vhdl-reserved-identifiers.vhd t/corpus/direct_rhs_concat_pack.fsm
---

Declared module/port/storage/constant/packed-type VHDL keywords now map to
collision-free names: OUT_identifier and ACCESS_identifier. Actual declaration
identities and references change; strings, comments and SV grammar survive.
Actual SV keyword declarations and basic reserved generic source names refuse.
Name discovery never evaluates symbolic ranges; source binding/width identities
and namespace guards remain authoritative.

ISF-REDUCTION-DELIVERY.22.2 repairs the prior OUT compiler rejection and T114
ACCESS refusal. Focused generic/declaration/APB tests pass. Authenticated local
GHDL 6.0.0 LLVM-JIT accepts fresh OUT, APB and scalar-generic APB artifacts.
Analysis only; no elaboration/runtime/general-profile claim.
Evidence: docs/audits/push-readiness-20261025/vhdl-reserved-repair.json.gz;
Failures: prior diagnosis/full6 intake.
