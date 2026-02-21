# CHANGES
This is the persistent technical change history for FSMGen.

## 2026-02-21
### Parser and expression handling
- Added parser support for compound update shorthand and inline modifiers:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - Inline forms in assignments such as `(A <- B (+= 2))` and `(A = B (-= 1))`
- Fixed nested packed conditional parsing for forms encoded as:
  - `['<',  [cond, action1, ...]]`
  - `['<!', [cond, action1, ...]]`
- Improved expression parsing for packed recursive operands and scalar negation tokens (e.g. `!wren`).

### Backend behavior hardening
- Added explicit `generate_verilog()` path in `perl/FSM/HDL/FlattenedDT.pm` with SystemVerilog-to-Verilog conversion (`always_comb`→`always @*`, `always_ff` lowering).
- Added explicit `generate_vhdl()` method that fails with a clear not-implemented error instead of method-missing crashes.
- Fixed indexed-target handling in flattening paths where direct `->name` assumptions caused runtime failures.

### Combinational self-dependency safety rule (`=`)
- Enforced generalized rule: combinational assignment RHS must not depend (directly or transitively) on the same LHS.
- Implemented graph-based dependency tracking for `=` assignments in `perl/FSM/Adapter/FSMGenFull/Parser.pm`:
  - Record `LHS -> RHS signals` for each combinational assignment.
  - Detect cycles per LHS and reject with `Carp::confess`.
- Preserved synchronous legality: loopback forms like `(A <- A)` remain allowed.

### Tests
- Added focused regression file: `t/02-combinational-self-dependency.t`
  - Direct reject: `(A = A)`
  - Indirect reject: `(A = B)` + `(B = A)`
  - Positive allow: `(A <- A)`
- Validated with:
  - `prove -v t/02-combinational-self-dependency.t`
  - `prove -v t/01-regression.t` (20/20 pass).

### Documentation consolidation
- Consolidated and refreshed root docs (`README.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`).
- Promoted and renamed user guide to `docs/USER_GUIDE.md`.
- Removed stale/duplicate investigation-era markdown files from `docs/`.

## 2025-08 (consolidated historical highlights)
- Fixed intermediate signal declaration/filtering defects in `FlattenedDT.pm`, including reference-aware and multi-registry dependency tracking.
- Fixed intermediate self-reference generation during multi-pass substitution.
- Fixed conditional transition suffix parsing (`<sig`, `<!sig`) for correct enable differentiation.
- Fixed operator selection and register feedback defaults for cleaner, synthesis-friendly RTL.
- Stabilized width inference behavior and parser/generator robustness across large FSM inputs.

## Earlier foundational changes
- Refactored monolithic FSM adapter flow into modular parser components (`SignalManager`, `ExpressionBuilder`, `Parser`, `SignalAnalyzer`).
- Standardized fatal error reporting with `Carp::confess`.
- Established baseline regression infrastructure (`t/01-regression.t`) and project self-containment.
