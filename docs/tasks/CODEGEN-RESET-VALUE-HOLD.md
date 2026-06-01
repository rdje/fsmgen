# CODEGEN-RESET-VALUE-HOLD: a reset-value register must hold, not revert to its reset value each cycle

## Metadata

- Tree ID: `CODEGEN-RESET-VALUE-HOLD`
- Status: `done`
- Roadmap lane: core HDL codegen (EnableGraph synthesis); blocks `ISF-REGISTER-RESET-VALUES`
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Summary

A flopped register that carries a reset value reverts to that reset value every
cycle it is not explicitly written, instead of **holding** its current value. The
combinational next-state default is being set to the reset literal rather than to
the flop's own feedback.

For a `register_out` flop the backend emits:

```systemverilog
always_comb begin
  x_next = 200;       // BUG: reset literal used as the comb hold default
  if (x__5_en) x_next = 5;
end
always_ff @(posedge clk) begin
  if (!rst_n) x <= 200;   // correct: reset value in the reset branch
  else        x <= x_next;
end
```

Because `x_next` defaults to `200`, any cycle in which `x__5_en` is low drives
`x <= 200` — the register cannot retain a written value. A comparison register
without a reset value correctly emits `o_next = o; // Default value` (feedback).

### Witness

```lisp
(actor hold
  (interface (input start) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (reset 200))
    (set x 5)
    (wait 3)
    (update o x)
    (complete done)))
```

`verilator --binary` simulation observes `o == 200` (the reset value) where the
held write should give `o == 5`. verilator-lint and yosys both PASS — the bug is
purely functional, so only simulation reveals it.

## Root cause

`FSM/Synthesis/EnableGraph/SignalSupport.pm::get_default_value_from_ast` consults
the AST/​signal `reset_value` and returns it as the combinational default (added
by `deddd971` / `bcb204cc`, R8 "expression-backed init"). That value flows into
`build_multiplexer_config`'s `multiplexer->{default_value}`
(`AssignmentSupport.pm` ~L742) and is emitted as `<reg>_next = <reset>` for
`register_out` flops (`AssignmentSupport.pm` ~L954). The reset value already has
its own, correct path to the reset branch via `get_reset_value_from_ast`
(`AssignmentSupport.pm` ~L974-982), so using it as the comb default is wrong for
a flopped register.

This is pre-existing R8 code, never exercised until `ISF-REGISTER-RESET-VALUES`
became the first feature to put a reset value on a register that must hold across
cycles.

## Fix

A flopped register's combinational next-state default must be its hold feedback
(the signal itself), never the reset value. Gate the `reset_value` branches in
`get_default_value_from_ast` on "not a register": pass the already-computed
`is_register` flag from `build_multiplexer_config` so registers fall through to
the feedback default (`get_default_value`, which returns the signal name). The
explicit AST `default_value()` branch and the comb (`=`) call site are
unchanged, preserving R8's behavior for non-registers.

## Acceptance Criteria

- The witness simulates to `o == 5` (the held value), and a no-reset register
  still holds (`o_next = o`). A reset-value register still resets to its value at
  `!rst_n`. verilator-lint + yosys clean. A focused t/ regression simulates the
  hold. Full `prove t/` green. Committed via `COMMIT.md`.

## Slice plan

- `.1` select + this doc (no code). `done`.
- `.2` gate the reset-value comb default on `is_register`; focused simulation
  test (hold across a wait); full regression. `done`.

## Implementation

- `SignalSupport.pm::get_default_value_from_ast($self, $lhs_ast, $is_register = 0)`
  — the `reset_value` branches (AST `reset_value()`, signal `get_attribute`,
  signal `attributes`) are now gated `unless ($is_register)`. A register falls
  through to the feedback default (`get_default_value`, which returns the signal
  name). The explicit AST `default_value()` branch is unchanged.
- `AssignmentSupport.pm::build_multiplexer_config` passes the already-computed
  `$is_register` into `get_default_value_from_ast`. The comb (`=`) call site in
  `initial_group_source_expr` is unchanged (defaults `$is_register` to 0), so
  combinational LHS keep prior behavior.
- The reset value continues to reach the reset branch via
  `get_reset_value_from_ast` (`AssignmentSupport.pm` ~L974-982) — unchanged.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1400` (3 subtests: held local, no-reset local, held CSR storage var); witness `verilator --binary` sim now reads `o == 5` (was 200); generated SV shows `x_next = x` + `x <= 200` reset branch; verilator-lint + yosys clean; full `prove t/` | `PASS` |

## Blockers

- None. `ISF-REGISTER-RESET-VALUES` is functionally incomplete until this lands;
  both are unpushed, so no released artifact carries the broken hold.

## Changelog

- `2026-06-02`: Created. Found via simulation while spiking bit-ops on
  reset-value locals — a reset-value register did not retain a written value.
  Confirmed pre-existing R8 backend conflation of reset value and comb default.
  Related: [[multi-expression-set-alias-bug]] (the other simulation-only codegen
  bug), `ISF-REGISTER-RESET-VALUES`.
