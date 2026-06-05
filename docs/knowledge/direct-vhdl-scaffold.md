---
id: direct-vhdl-scaffold
title: Direct single-FSM VHDL generation has a scoped scaffold
answers:
  - "is VHDL still not implemented?"
  - "does --language vhdl work for direct FSM roots?"
  - "what VHDL subset is shipped?"
  - "does direct VHDL support aggregate outputs?"
  - "is composition VHDL supported?"
  - "is GHDL validation active?"
date: 2026-06-05
status: current
tags: [vhdl, backend, direct-generation, validation]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Support/HDLExternalValidationContract.pm; docs/VHDL_SCOPE.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t t/308-systemverilog-external-validation.t
---

Direct single-FSM roots can now use `target_language => 'vhdl'` or
`--language vhdl` for the shipped scaffold subset: scalar/vector ports, state
constants, enable assignments, sync/async reset processes, `process(all)`
combinational muxes, and basic concat RHS forms. Composition/top VHDL,
aggregate-output VHDL, packages, multi-clock domains, broad expression parity,
GHDL validation, and full SystemVerilog parity remain deferred or fail-closed.
