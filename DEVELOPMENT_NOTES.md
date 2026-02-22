# DEVELOPMENT_NOTES
This document captures engineering rationale, design constraints, and working decisions behind recent FSMGen behavior.

## 2026-02-22: Phase-1 intent model clarification (`<-` vs `<=`)
- Assignment intent is now explicitly captured at AST assignment nodes (`assignment_intent`, `source_provenance`, `output_exposure`).
- The `<=` semantic intent is explicitly encoded as:
  - `register_style = input_named`
  - `lhs_binding = flop_d_input`
  - `immediate_visibility = same_cycle_on_d_input`
  - `hold_policy = q_feedback_when_no_enable`
- The `<-` semantic intent is explicitly encoded as:
  - `register_style = output_named`
  - `lhs_binding = flop_q_output`
  - `hold_policy = q_feedback_when_no_enable`

This preserves the intended modeling distinction:
- `<-` names/registers the flop output (`Q`) as LHS.
- `<=` names the flop input side (`D`) as LHS while maintaining storage behavior by feedback when enables are inactive.

## Current parser/generator model
- Parse flow is modularized into `SignalManager`, `ExpressionBuilder`, `Parser`, and `SignalAnalyzer`.
- Fail-fast behavior uses `Carp::confess` with stack traces instead of silent parser failures.
- The regression baseline remains CLI-level (`prove -v t/01-regression.t`) to validate real generation paths.

## Assignment semantics and safety policy
### Semantics
- `=` is combinational.
- `<-` and `<=` are synchronous/flopped forms.

### Safety rule
- Combinational assignments must not create self-dependency:
  - direct (`A = A`)
  - indirect/transitive (`A = f(B)`, `B = g(A)`)
- Synchronous feedback is valid (`A <- A`) and intentionally preserved.

## Why graph-based combinational validation was chosen
Direct text checks are insufficient because harmful dependence can be indirect.  
Decision:
- Track combinational dependencies as graph edges (`lhs -> rhs signal`) during parse.
- Validate cycle reachability per combinational target before module return.
- Reject with explicit error if any path returns to the same target.

Benefits:
- One generalized guard handles all `A = f(...)` cases.
- Order-independent detection (works regardless of statement order in source).
- Clear extension point for future combinational rule checks.

## Parser improvements retained
- Compound update shorthand and inline forms are supported:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - `(A <- B (+= 2))`, `(A = B (-= 1))`
- Packed nested condition encoding is handled:
  - `['<', [cond, ...]]`
  - `['<!', [cond, ...]]`
- Scalar negation tokens and packed operands are normalized in expression parsing.

## Backend status rationale
- Verilog path exists via SystemVerilog emission followed by deterministic textual lowering.
- VHDL path is intentionally explicit not-implemented rather than failing with missing method errors.
- This prevents ambiguous failures and keeps CLI behavior predictable.

## Documentation consolidation policy (current)
- Canonical top-level docs:
  - `README.md` (overview + quickstart)
  - `CHANGES.md` (persistent technical history)
  - `DEVELOPMENT_NOTES.md` (this file; rationale and context)
- Canonical user guide:
  - `docs/USER_GUIDE.md`
- Investigation-era and duplicate docs are removed once their conclusions are merged into canonical files.

## Ongoing engineering expectations
- Keep debug messages traceable with clear `[file][function()]` context.
- Prefer AST-based generation/transforms over regex-driven rewrites.
- Add focused regression tests for every parser/generator rule that can silently regress.
