# 0001 — ISF abstraction layering (ISF = IAL1)

- Date: 2026-06-02 (migrated from harness-home memory; fact predates this date)
- Type: architecture
- Status: accepted

## Context

FSMGen has layered intermediate languages. There is recurring ambiguity about
where a new high-level construct belongs: the ISF surface, a desugar into existing
ISF, or the ATL (actor-network) layer.

## Decision

- **ISF is IAL1** (intermediate abstraction layer 1).
- **High-level-language sugar** (variables, inline functions, compound/bit/field
  ops, conditional assignment, min/max, rotate, swap, …) **desugars into ISF** — it
  does not get its own lowering layer. The session's theme-3 constructs are all
  pure parser desugars to existing ISF/`.fsm` ops.
- **Only genuinely new models** (new concurrency/actor-network semantics) go to
  **ATL**. A construct that can be expressed by rewriting to existing ISF clauses
  is sugar, not a new model.

## Consequences

- New ergonomic constructs are implemented as parser desugar passes in
  `FSM::Adapter::ISF::Parser` (e.g. `_expand_bit_ops`, `_expand_selects`), not as
  new lowerer primitives — keeping the lowering/HDL backend stable.
- A primitive that does NOT desugar to existing ops (e.g. `(assert COND)` → SVA) is
  a genuinely new lowering concern and is scoped accordingly (see
  `docs/tasks/ISF-ASSERT.md`), not forced into the sugar mold.
- The path is always **ISF → `.fsm` → SV** (no direct ISF→SV channel); anything a
  construct must reach the backend with has to survive the `.fsm` text.
