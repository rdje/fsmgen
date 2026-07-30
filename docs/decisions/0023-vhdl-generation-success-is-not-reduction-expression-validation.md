# 0023 — VHDL generation success is not reduction-expression validation

- Date: 2026-07-30
- Status: accepted
- Type: learning / backend qualification

## Context

The named-drive rule/transaction priority contract generated its
protocol-neutral probe through SystemVerilog, Verilog, and VHDL. SystemVerilog
has assertion-enabled Verilator evidence, and Icarus 13.0 compiled the native
Verilog output. The direct VHDL command returned success but emitted
`drive_zero_en and (|drive_zero_start)`, preserving a SystemVerilog unary
reduction token in VHDL.

`_sv_expr_to_vhdl` in `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm` translates
spaced binary `|` but has no unary reduction branch or rejection. No VHDL
compiler is installed, and the existing external-validation contract is
explicitly SystemVerilog-only.

## Decision

A successful direct VHDL generation command is not evidence that a newly
exercised expression family is syntactically or semantically VHDL-qualified.
Qualification requires either an authoritative VHDL compile/runtime lane or a
bounded, regression-backed translator/fail-closed contract for the exact
expression shape.

Named-drive priority implementation may proceed on the SystemVerilog-backed
and native-Verilog-qualified path because the reduction leak predates that
repair and is independently owned. It must report VHDL as unqualified and must
not absorb the backend fix. Proposed task
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` owns unary reduction translation or
rejection and later compiler qualification.

## Consequences

- mdBook and task records must not equate VHDL file emission with valid VHDL.
- Backend probes must report each target's evidence level separately.
- The named-drive `.3` gate includes VHDL characterization but no VHDL-validity
  claim.
- A later clean selector may activate the proposed reduction-expression tree
  without reopening named-drive priority semantics.
- The exact repository-local three-file/19,070-byte probe was removed after
  its evidence was recorded.
