---
id: aggregate-typedef-module-ownership
title: Generated aggregate typedef names belong to their emitting module
answers:
  - "why did aggregate composition emit duplicate typedef declarations?"
  - "how are SystemVerilog aggregate typedef names isolated across modules?"
  - "does module scoping of typedefs change semantic type compatibility?"
date: 2026-09-27
status: current
tags: [aggregates, types, composition, systemverilog, backend]
evidence: perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm; perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm; t/1906-aggregate-typedef-module-ownership.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1906-aggregate-typedef-module-ownership.t t/280-declarative-aggregate-types.t
---

Port typedefs are emitted at compilation-unit scope. A fresh alias-only name
allocator per module therefore produced duplicates in otherwise valid composed
HDL. Both direct and structural emitters now give `typedef_state` the actual
module name; `TypeDeclarationSupport` adds an injective length-delimited module
prefix before the existing alias-derived, collision-checked suffix. Internal
and port declarations share the module state, which Orchestrator resets per run.

This is backend naming, not a change to semantic type equality or layout.
T1906 checks distinct names, packed-value runtime for equal/different/nested
record/list types, generator reuse, delimiter/sanitization collisions and
same-width incompatible-type rejection. Broader generated-child aggregate
storage routing remains separately qualified under `.39.2.2.2.2.2`.

Repeated instances of the same source also exposed duplicated module bodies:
GenerationOrchestrator currently concatenates each instance's full HDL. That
separate defect is owned by `.42`; scoped typedefs do not repair it. Ownership:
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.2.2.1`.
