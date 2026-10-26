---
id: composition-scalar-binding-renderer
title: Canonical scalar composition rendering preserves scoped parameter names
answers:
  - "where does canonical scalar composition binding rendering live?"
  - "does scalar composition expression rendering enable parameterized HDL plans?"
date: 2026-10-26
status: current
tags: [composition, parameters, lowering, verilog]
evidence: perl/FSM/Backend/VerilogFamily/CompositionBindingEmitter.pm; t/2132-composition-scalar-binding-renderer.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2132-composition-scalar-binding-renderer.t
---

The internal renderer returns expression text and ordered actual parameter
references from scoped canonical binding nodes. It never substitutes parameter
validation values. Static scalar payloads use canonical literal normalization;
raw expression text and aggregates refuse. It does not enable source plans or
change either structural emitter's pending guard. See the
[composition reference](../book/src/05-composition-basics.md) for applicability.
