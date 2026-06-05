---
id: flattened-generation-mode-boundary
title: HDL generation mode is flattened_debug_first and not constructor-selectable
answers:
  - "is non-flattened generation supported?"
  - "does HDLGenerator accept generation_mode?"
  - "what is the default generation mode?"
  - "where is flattened generation mode advertised?"
  - "can embedders select structured generation?"
date: 2026-06-05
status: current
tags: [backend-generation, embedding, capability-manifest, flattened]
evidence: perl/FSM/Support/HDLGeneratorFacadeContract.pm; perl/FSM/Pipeline/HDLGenerator.pm; perl/FSM/Backend/GeneratedModuleEmitter.pm; t/375-hdl-generator-facade-contract.t; t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t; t/297-capability-manifest.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/375-hdl-generator-facade-contract.t t/414-hdl-generator-facade-constructor-option-name-boundary-audit.t t/297-capability-manifest.t
---

FSMGen's current generated-module backend mode is `flattened_debug_first`.
`embedding.hdl_generator_facade` advertises that through
`default_generation_mode`, `generation_mode_names`, and
`structured_nonflattened_generation_status`, but `generation_mode` is not a
public constructor option. `FSM::Pipeline::HDLGenerator->new(...)` rejects
`generation_mode` as an unsupported option until a real structured or
non-flattened backend path is implemented and regression-backed.
