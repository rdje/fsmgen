---
id: isf-property-grammar-location
title: Where the ISF verification property grammar lives (parse + render to SVA)
answers:
  - "where is the ISF assert/assume/cover property grammar?"
  - "how do I add a property combinator or operator to ISF checks?"
  - "where does (=> A B) / next / within / after / sampled-value get parsed and rendered to SVA?"
  - "does ISF validate the assert condition or pass it through?"
  - "where is the verilator-simulable vs formal-only (ifndef SYNTHESIS / ifdef FORMAL) split decided?"
date: 2026-06-04
status: current
tags: [isf, verification, properties, assert, sva]
evidence: perl/FSM/Adapter/FSMGenFull/Parser.pm (parse_check_property); perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm (_render_check_condition_sv, _property_is_formal_only); perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm (_analyze_check_condition_references)
reverify: grep -n "sub parse_check_property" perl/FSM/Adapter/FSMGenFull/Parser.pm
---

The ISF verification property grammar (the `COND` of `(assert/assume/cover COND)`)
is **not** in the ISF lowerer. ISF passes `COND` through **verbatim**:
`FSM::Scheduler::ISF::LoweringIR::_format_isf_expr` is a pure recursive serializer
(no operator whitelist) and `_ir_check` just serializes it into the `+assert`
carrier. All property grammar + validation lives at the `.fsm` re-parse layer:

- **Parse** — `FSM::Adapter::FSMGenFull::Parser::parse_check_property`: recognizes the
  combinators (`=>`, `after`, `next`, `within`, sampled-value `stable/changed/rose/fell`)
  as tagged `{__property__=>1, op=>…}` structs; anything else falls through to the
  boolean expression builder. **Add a new combinator/leaf here.**
- **Render to SVA** — `FSM::Pipeline::GeneratedModuleInfoBuilder::_render_check_condition_sv`
  maps each `op` to SV text (`|->`, `##1`, `##[1:N]`, `$rose(…)`, `$stable(…)`, …).
- **Checkability split** — `_property_is_formal_only` (same file): a `##` delay
  (`next`/`within`) is **formal-only** (`` `ifdef FORMAL ``); everything else is
  verilator-simulable (`` `ifndef SYNTHESIS ``). It recurses into
  `antecedent`/`consequent`/`operand`/`trigger`.
- **Keep-alive** — `FSM::Adapter::FSMGenFull::SignalAnalyzer::_analyze_check_condition_references`
  walks the same fields, so a signal used only in a check stays a port.

Because the formal-only and aliveness walks already recurse into `operand`, a new
one-operand leaf (e.g. `ISF-PROPERTY-SAMPLED-VALUE`'s `sampled_value` op) gets
both behaviors for free. See [[isf-lowering-pipeline]].
