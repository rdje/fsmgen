---
id: abc-discovery-validation-boundary
title: ABC mapping is optional and explicit opt-in
answers:
  - "does --verify-hdl run abc?"
  - "is yosys-abc required for external validation?"
  - "why does hdl external validation report abc_mapping?"
  - "what is the ABC mapping hardening boundary?"
  - "does FSMGen require ABC for Yosys validation?"
date: 2026-06-06
status: current
tags: [backend-validation, abc, yosys, capability-manifest]
evidence: perl/FSM/Support/HDLExternalValidation.pm; perl/FSM/Support/HDLExternalValidationContract.pm; t/308-systemverilog-external-validation.t; t/313-hdl-external-validation-contract.t; t/297-capability-manifest.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/313-hdl-external-validation-contract.t t/297-capability-manifest.t t/308-systemverilog-external-validation.t
---

`--verify-hdl` does not run ABC and does not require an ABC executable. The
external validation lane still requires only Verilator and Yosys, and Yosys is
run with `synth -noabc`. `hdl_external_validation_tools()` reports the first
optional ABC mapping candidate found from `yosys-abc`, `berkeley-abc`, and
`abc` under `abc_mapping` / `abc_mapping_tool` so the public contract and
capability manifest can distinguish required validation tools from later
ABC-mapping hardening metadata.

`FSM::Support::HDLExternalValidation::validate_systemverilog_file(...,
abc_mapping => 1)` is now the explicit in-process opt-in for ABC-backed Yosys
mapping validation. That path requires optional ABC discovery and runs a
`yosys_abc_synthesis` step with `synth -top`. It does not change the default
`--verify-hdl` CLI behavior and does not make ABC a required external
validation tool.
