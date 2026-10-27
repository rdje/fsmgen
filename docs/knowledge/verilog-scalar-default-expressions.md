---
id: verilog-scalar-default-expressions
title: Direct Verilog-family scalar defaults retain canonical relationships
answers:
  - "do direct scalar arithmetic defaults retain parameter names in HDL?"
  - "why do direct HDL headers refuse after changing a captured declaration?"
date: 2026-10-27
status: current
tags: [verilog, parameters, defaults, lowering]
evidence: perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; t/2147-direct-scalar-default-headers.t; docs/book/src/04-symbols-types-and-imports.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2147-direct-scalar-default-headers.t t/2143-direct-scalar-parameter-alias-emission.t t/2110-ial0-parameter-default-sources.t t/30-language-contract-symbol-definitions.t
---

Direct SystemVerilog and compatibility Verilog headers consume supported
canonical scalar trees. Immediate roots, operator nesting, static selections
and dependency order survive independently of cached validation numbers.
Independent names keep alphabetical ties. Complete captured source/binding
membership and lexical ownership are required; a declaration update clears the
binding map and prevents stale fallback. Physical copies retain source scope.

The named corpus fixture covers actual native and emitted header shape.
Immutable aggregate operands now fold through the direct default profile;
mutable aggregate/path dependencies explicitly refuse, including scalar
comparison results. The `direct-aggregate-default-profile` card owns that
boundary. Generic ranges, VHDL and complete external override/runtime/public
qualification remain separate.
