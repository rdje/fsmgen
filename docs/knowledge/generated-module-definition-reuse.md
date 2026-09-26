---
id: generated-module-definition-reuse
title: Repeated generated instances share a verified HDL definition
answers:
  - "why did repeated generated sources emit duplicate HDL modules?"
  - "how does composition reuse definitions without merging instance state?"
  - "why does repeated-worker await_all hang despite correct child results?"
date: 2026-09-27
status: current
tags: [composition, instances, module-definitions, isf, completion]
evidence: perl/FSM/Composition/ModuleDefinitionCollector.pm; perl/FSM/Composition/GenerationOrchestrator.pm; t/1907-composition-module-definition-ownership.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1907-composition-module-definition-ownership.t t/189-composition-generation-orchestrator.t t/292-composition-generated-child-parameter-overrides.t
---

GenerationOrchestrator previously concatenated full HDL from every realized
instance. ModuleDefinitionCollector now groups payloads by declared module
identity (case-insensitive for VHDL), verifies exact definition agreement and
emits the first payload once. Only the known scaffold header Date metadata is
ignored for comparison; body comments/code remain significant and the emitted
payload stays unchanged. Conflicting definitions and generated-top collisions
fail contextually. Instances, parameter overrides, bindings and provenance
remain separate, so definition reuse does not share their registers.

T1907 independently simulates repeated direct scalar/aggregate/parameterized
instances and separate ISF worker-local results, including normal and repeated
completion. `.43` repairs staggered done-pulse joins with per-activation parent
completion memory; the original runtime completion expectations now pass
without TODOs. See `generated-child-completion-memory.md` for that behavior.
