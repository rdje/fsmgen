# 0002 — ISF high-level-language richness frontier

- Date: 2026-06-02 (migrated from harness-home memory)
- Type: project
- Status: accepted (in progress)

## Context

The product vision is that ISF (later ATL) should "feel like programming in a
high-level language" that lowers to `.fsm`/HDL — rich in constructs for chip
design and intent capture. Four sanctioned themes (any order):
(1) conditional child activation, (2) nested cross-domain CDC,
(3) new intent-capture constructs, (4) ATL actor networks.

## Decision

Pursue the four themes autonomously (see `0003`). Theme 3 (intent-capture
constructs) is the high-level-language ergonomics surface.

## Consequences (theme-3 surface shipped as of 2026-06-02)

A comprehensive data/arithmetic/bit/field surface, each a pure parser desugar
(per `0001`), verilator-lint + yosys clean, and `verilator --binary`-simulated,
with runnable book examples (`docs/book/src/13e`, matrix row `13k`):

- Assignment: `(select DST COND A B)`, `(max/min DST A B)`, `(swap A B)`
- Counters: `(incr/decr NAME [by N])`
- Bits: `(set-bit/clear-bit/toggle-bit NAME N)`, `(when-bit/unless-bit NAME N body…)`
- Fields: `(set-field NAME (bits HI LO) V)`, `(when-field/unless-field NAME (bits HI LO) V body…)`
- Shift/rotate: `(rotate-left/right REG [by N])`

Two correctness bugs found by simulation and fixed along the way:
`CODEGEN-RESET-VALUE-HOLD` (reset-value registers must hold) and
`CODEGEN-MULTI-EXPRESSION-SET-ALIAS` (per-write-site enables; unblocked
select/min/max/swap/clamp).

Next theme-3 thread: `(assert COND)` verification intent (`docs/tasks/ISF-ASSERT.md`).
The clean quick-win desugar vein is otherwise saturated; further additions need
bigger infrastructure (SVA emission) or are marginal.
