# ISF-ASSERT-CONCURRENT: clocked concurrent SV properties for assert/assume/cover

## Metadata

- Tree ID: `ISF-ASSERT-CONCURRENT`
- Status: `active`
- Roadmap lane: `R14` (ISF — verification intent)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal (step 1 of `docs/decisions/0008`)

Re-point the user-facing immediate checks `(assert|assume|cover COND)` from
immediate combinational assertions (`assert (COND)` in `always_comb`) to **clocked
concurrent SV properties**, which is the correct verification semantic for a
synchronous FSM:

```systemverilog
`ifndef SYNTHESIS
  assert property (@(posedge clk) disable iff (<reset-active>) (COND)) else $error("…");
  assume property (@(posedge clk) disable iff (<reset-active>) (COND));
  cover  property (@(posedge clk) disable iff (<reset-active>) (COND));
`endif
```

Wins: clock-edge sampling (no combinational-transient false fires) and reset
gating (the immediate form had **no** reset guard → would fire on reset/X). No new
ISF language — pure emitter change.

## Design

- The emitter (`GeneratedModuleEmitter::immediate_assertion_runtime_lines`) already
  has `module_info`, which carries `system_contract` = `{ clock, reset,
  reset_active_level, … }`. Build `@(posedge <clock>)` and `disable iff
  (<reset-active>)` from it (`reset-active = reset_active_level ? reset : "!reset"`,
  matching the FSM's own `reset_condition_expr`).
- Concurrent assertions are module items (not inside `always_comb`): drop the
  `always_comb` wrapper; emit each `<kind> property (...)` directly under
  `` `ifndef SYNTHESIS ``. `assert`/`assume` keep `else $error("msg")`; `cover` is
  bare. Omit `disable iff` when no reset; **fall back** to the immediate
  combinational form when there is no clock (defensive).
- Verilog (non-SV) output stays assertion-free (unchanged).

## Slice plan

- `.1` select + design (this doc) + decision `0008`.
- `.2` the emitter switch + tests (`t/1411` updated to the property form; a
  `verilator --binary --assert` clocked pass/fire run) + docs (13d/13k note the
  clocked-property lowering). verilator-lint + yosys clean; full suite green.

## Non-Goals

- Temporal operators (`|->`, `##`) — that is `ISF-PROPERTY-IMPLICATION` (step 2).
- Removing `(contract …)` — a later slice once the property language can express
  its intent (`0008`).

## Acceptance Criteria

- `(assert/assume/cover …)` emit clocked concurrent properties with `disable iff`
  reset gating; verilator-lint + yosys clean; `verilator --binary --assert` shows
  silent-on-pass / fires-on-violation at the clock edge; Verilog assertion-free;
  full suite green; docs + tests updated; committed via `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created on the user's go-ahead for steps (1)+(2) of `0008`. Confirmed
  `module_info->{system_contract}` already carries clock/reset/active-level, so this
  is a focused emitter change.
