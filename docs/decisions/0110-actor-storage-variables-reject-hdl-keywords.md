# 0110 — Actor storage variables reject HDL keywords

- Date: 2026-09-27
- Type: language contract
- Status: accepted
- Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.3

## Context

A public strict ISF check accepted `(var cell (width 4))` and emitted `cell`
as a register and generated child input. Independent Verilator compilation
rejected those declarations because the spelling is a SystemVerilog keyword.
The parser checked only identifier shape. The shared registry already knows
this keyword, but decision 0027 applied it only to child instance labels.
Four recent formal-preparation controls consequently checked strict carriers
without proving their keyword-named HDL compilable.

## Decision

Actor storage `var` and `variable` names must be simple identifiers and must
not be reserved by the shared shipped-target keyword union. SystemVerilog
matching remains case-sensitive; VHDL matching remains case-insensitive.
Reject at source parsing with actor, variable name, reserving target and rename
guidance. Keep one backend-neutral source identity; do not silently rename or
introduce target-specific escaping for authored storage names.

A bank name is a logical owner, not an emitted signal spelling. Its element
names use numeric suffixes, so keyword logical names remain admitted when
the actual scalarized names satisfy the existing collision/shape contracts.
Field metadata likewise does not become an independent authored register.

## Consequences

Invalid variable sources now produce an early classified failure instead of
apparently successful invalid HDL. Legal non-keyword source/report/HDL names
remain unchanged. Formal-preparation controls use `value_reg`, with separate
keyword-negative coverage and independent legal-control compilation.

This bounded contract extends 0027 only for ISF actor storage variables; other
identifier families and direct FSM declarations retain their separately owned
contracts. It does not claim global HDL identifier completeness or extend
storage access metadata. The original compiler failure stays retained under
the owning task, alongside the independently isolated read-guard defect.
