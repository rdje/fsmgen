---
id: verilog-scalar-default-aliases
title: Verilog-family direct module headers preserve scalar default aliases
answers:
  - "do direct scalar parameter aliases now retain names in generated Verilog?"
  - "how are direct module scalar alias declarations ordered?"
date: 2026-10-27
status: current
tags: [verilog, parameters, lowering, defaults]
evidence: perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; t/2143-direct-scalar-parameter-alias-emission.t; docs/book/src/04-symbols-types-and-imports.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2143-direct-scalar-parameter-alias-emission.t t/2110-ial0-parameter-default-sources.t t/30-language-contract-symbol-definitions.t
---

The shared direct-module scaffold renders captured scalar default trees through
the shared target helper, retaining bounded alias-source consistency checks. It preserves selected names
and emits dependencies first, keeping alphabetical ties for independent names.
Equal literals/static defaults never acquire an inferred alias. Inconsistent
observations, undeclared or non-scalar targets and alias cycles refuse.

Scalar operators now retain actual root operands too. Aggregate/path defaults,
symbolic ranges, VHDL and external override/runtime qualification remain
separately owned. Normalized Core parameter values keep their existing schema
and selected-default meaning; executable R11 parameter references are unchanged.
