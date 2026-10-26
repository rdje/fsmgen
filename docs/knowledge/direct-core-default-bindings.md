---
id: direct-core-default-bindings
title: Direct Core defaults retain canonical scoped binding snapshots
answers:
  - "where does direct Core retain canonical scoped parameter default bindings?"
  - "what invalidates direct module default binding snapshots?"
date: 2026-10-27
status: current
tags: [parameters, core, binding, provenance]
evidence: perl/FSM/CoreAST.pm; perl/FSM/Adapter/FSMGenFull/Parser.pm; t/2145-direct-core-default-bindings.t; docs/book/src/04-symbols-types-and-imports.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2145-direct-core-default-bindings.t t/2110-ial0-parameter-default-sources.t t/2117-canonical-parameter-declaration-graph.t
---

The direct parser requests the existing canonical expression capture and binds
its actual declared observations through the shared helper. Core's detached
`parameter_default_bindings()` map retains immediate roots, aggregate paths,
source scope and frozen static selections. Constants, enum members and imported
leaves retain the selected canonical payload kinds; equal values do not invent
parameter identity. The three-argument registration callback and normalized
parameter/authored-source/IntentHIR products keep their previous shape.

Declaration replacement clears the entire derived map. Nonempty retries clear
it before resolution and publish only after complete binding; missing declared
observations cannot fall through to the parameter-valued compatibility cache.
Explicit constructor copies preserve the captured source owner across physical
renames. Getters and bulk updates are detached. Lifetime checks cover actual
literal/alias parameter paths; separate static-resolver retention remains owned
by `ISF-REDUCTION-DELIVERY.19`. General-default HDL consumers remain pending.
