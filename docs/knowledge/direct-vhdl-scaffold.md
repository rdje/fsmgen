---
id: direct-vhdl-scaffold
title: Direct single-FSM VHDL generation has a scoped scaffold
answers:
  - "is VHDL still not implemented?"
  - "does --language vhdl work for direct FSM roots?"
  - "does --language vhdl work for composition tops?"
  - "does target_language vhdl work for composition roots?"
  - "what VHDL subset is shipped?"
  - "does direct VHDL support aggregate outputs?"
  - "is composition VHDL supported?"
  - "is GHDL validation active?"
  - "does direct VHDL support delayed pulses?"
  - "does direct VHDL support arithmetic expressions?"
  - "does direct VHDL support multi-operand addition?"
  - "does direct VHDL support subtraction chains?"
  - "does direct VHDL support multiplication chains?"
  - "does direct VHDL support division/modulo chains?"
  - "does direct VHDL support XOR chains?"
  - "does direct VHDL support scalar addition?"
  - "does direct VHDL support scalar addition chains?"
  - "does direct VHDL support scalar subtraction?"
  - "does direct VHDL support scalar subtraction chains?"
  - "does direct VHDL support scalar division?"
  - "does direct VHDL support scalar modulo?"
  - "does direct VHDL support scalar division/modulo?"
  - "does direct VHDL support scalar multiplication?"
  - "does direct VHDL support scalar multiplication chains?"
  - "does direct VHDL support numeric literal arithmetic?"
  - "does direct VHDL support compound update arithmetic?"
  - "does direct VHDL support signed declarations?"
  - "does direct VHDL support scalar bit declarations?"
  - "does direct VHDL support generics?"
  - "does direct VHDL support parameterized direct roots?"
  - "does direct VHDL support sized literal generic defaults?"
  - "does direct VHDL support vector sized literal generic defaults?"
date: 2026-06-06
status: current
tags: [vhdl, backend, direct-generation, validation]
evidence: perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Support/HDLExternalValidationContract.pm; t/1420-vhdl-direct-backend-scaffold.t; t/386-hdl-generator-facade-target-language-boundary-audit.t; t/114-composition-target-support-diagnostics.t; docs/VHDL_SCOPE.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t t/308-systemverilog-external-validation.t
---

Direct single-FSM roots can now use `target_language => 'vhdl'` or
`--language vhdl` for the shipped scaffold subset: scalar/vector ports, state
constants, enable assignments, sync/async reset processes, `process(all)`
combinational muxes, generic-bearing direct-root module headers, basic concat
RHS forms, and delayed-pulse clock-branch nested-if lowering. Generated
SystemVerilog `parameter` blocks for direct roots lower to VHDL generics before
the port block while the body keeps already-resolved concrete signal widths:
arithmetic integer-expression defaults become `integer` generics. Sized-literal
defaults become `std_logic` generics for one-bit defaults and
`std_logic_vector` generics for multi-bit defaults; the focused coverage uses
`params_aggregate_comparison` for the scalar case and
`params_aggregate_unary_complement` for the vector case. The
scaffold also lowers the first arithmetic RHS shape: scalar addition and
subtraction RHS forms and chains lower to one-bit truncated `xor` semantics,
and scalar multiplication plus scalar multiplication chains lower to one-bit
`and` semantics. Generated direct mux expressions with one vector signal and
one numeric literal operand for `+` or `-`, such as `SRC + 2` and
`byte_count + 4` from compound update/shorthand fixtures, lower through
target-width `to_unsigned` casts. Same-width vector `NAME + NAME` assignments
and same-width multi-operand
addition chains become
`std_logic_vector(unsigned(A) + unsigned(B) + ...)` expressions; same-width
vector subtraction chains become
`std_logic_vector(unsigned(A) - unsigned(B) - ...)` expressions.
Same-width vector multiplication chains become
`std_logic_vector(resize(unsigned(A) * unsigned(B) * ..., WIDTH))`
expressions. Same-width vector division/modulo chains become
`std_logic_vector(resize(unsigned(A) / unsigned(B) / ..., WIDTH))` and
`std_logic_vector(resize(unsigned(A) mod unsigned(B) mod ..., WIDTH))`
expressions. Scalar division/modulo RHS forms such as `A / B` and `A % B`
remain explicit fail-closed direct VHDL boundaries. Same-width scalar/vector XOR
chains become `A xor B xor ...`
expressions. Generated scalar `bit` internal declarations and signed vector
internal declarations such as `reg signed [3:0] NIB` remain unsupported in the
current direct VHDL scaffold and are selected as the next exact hardening leaf.
Four-state `logic` declarations, signed ports, and signed arithmetic semantics
remain outside that selected slice. Aggregate-output roots are locked as
explicit fail-closed direct VHDL boundaries by focused pipeline and facade
coverage. Composition/top VHDL is locked fail-closed by focused pipeline and
CLI coverage: `?top` sources are parsed into typed composition IR, then
`target_language => 'vhdl'` and `--language vhdl` are rejected with the scoped
composition target-support diagnostic instead of emitting a VHDL top.
Composition generic-map lowering, packages, multi-clock domains, broad
expression parity, GHDL validation, and full SystemVerilog parity remain
deferred or fail-closed.
