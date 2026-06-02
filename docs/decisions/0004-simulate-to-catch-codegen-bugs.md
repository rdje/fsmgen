# 0004 — Simulate control flow; lint/synth aren't enough

- Date: 2026-06-02 (migrated from the counted-repeat-termination learning + reinforced)
- Type: learning
- Status: accepted

## Context

Multiple real correctness bugs in generated HDL passed `verilator --lint` and
`yosys` synthesis cleanly and were caught **only by functional simulation**:

- Counted `(repeat N …)` did not terminate (loop-back reloaded the counter).
- Reset-value registers reverted to their reset value every idle cycle instead of
  holding (`CODEGEN-RESET-VALUE-HOLD`) — the reset literal was used as the
  combinational hold default.
- Two expression `(set)`s to one register aliased to one write-enable; the earlier
  write was silently dropped (`CODEGEN-MULTI-EXPRESSION-SET-ALIAS`) — a duplicate
  identical continuous assign is not a structural multi-driver, so the tools passed.

No gate simulates behaviour; lint and synth check structure/wellformedness, not
function.

## Decision

For any control-flow / sequential / codegen change, **verify with a
`verilator --binary` testbench** that exercises the actual behaviour (loop counts,
held values across cycles, pass-vs-fail of a condition), in addition to
`--verify-hdl` (verilator lint + yosys). Treat a clean lint/synth as necessary,
never sufficient.

## Consequences

- Each theme-3 construct this session shipped with a `verilator --binary`
  simulation proving its runtime behaviour (e.g. clamp `150→80`, rotate
  `0x81 rol1 → 0x03`, swap `77/200 → 200/77`).
- When a feature touches the FSM/codegen, write the simulating testbench *first* if
  practical; it is the only thing that catches this class of bug.
