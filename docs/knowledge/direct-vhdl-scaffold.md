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
  - "does direct VHDL support delayed pulses?"
  - "does direct VHDL support arithmetic expressions?"
  - "does direct VHDL support multi-operand addition?"
  - "does direct VHDL support subtraction chains?"
  - "does direct VHDL support multiplication chains?"
  - "does direct VHDL support XOR chains?"
date: 2026-06-06
status: current
tags: [vhdl, backend, direct-generation, validation]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Support/HDLExternalValidationContract.pm; t/1420-vhdl-direct-backend-scaffold.t; t/386-hdl-generator-facade-target-language-boundary-audit.t; docs/VHDL_SCOPE.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t t/308-systemverilog-external-validation.t
---

Direct single-FSM roots can now use `target_language => 'vhdl'` or
`--language vhdl` for the shipped scaffold subset: scalar/vector ports, state
constants, enable assignments, sync/async reset processes, `process(all)`
combinational muxes, basic concat RHS forms, and delayed-pulse clock-branch
nested-if lowering. The scaffold also lowers the first arithmetic RHS shape:
same-width vector `NAME + NAME` assignments and same-width multi-operand
addition chains become `std_logic_vector(unsigned(A) + unsigned(B) + ...)`
expressions; same-width vector subtraction chains become
`std_logic_vector(unsigned(A) - unsigned(B) - ...)` expressions.
Same-width vector multiplication chains become
`std_logic_vector(resize(unsigned(A) * unsigned(B) * ..., WIDTH))`
expressions. Same-width scalar/vector XOR chains become `A xor B xor ...`
expressions. Composition/top VHDL, aggregate-output VHDL, packages,
multi-clock domains, division/modulo, broad expression parity, GHDL
validation, and full SystemVerilog parity remain deferred or fail-closed.
