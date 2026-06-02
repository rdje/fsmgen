# 0008 — Unify verification on one property language (assert/assume/cover/contract)

- Date: 2026-06-02
- Type: architecture
- Status: accepted (direction); execution staged (`ISF-ASSERT-CONCURRENT`,
  `ISF-PROPERTY-IMPLICATION`, then a later `contract` fold-in)

## Context

ISF grew two unrelated verification mechanisms:
- `(assert/assume/cover COND)` — immediate combinational checks (`ISF-ASSERT`,
  `ISF-COVER-ASSUME`), emitted as `assert (COND)` in `always_comb`.
- `(contract NAME (eventually SIGNAL within CYCLES))` — a bounded-liveness
  property lowered to a synthesizable FSM *monitor* (arm/pending/age/fail signals).

Moving the immediate checks to **concurrent** SV (`assert property (@clk …)`)
exposes the real question (raised by the user): to capture what SV *properties*
capture you must express *temporal* intent at the ISF level (implication `|->`,
delay `##N`, `eventually`, `until`, `throughout`) — not just a boolean. And
`(contract …)` is already the narrowest slice of exactly that temporal intent, so
two parallel mechanisms is redundant.

## Decision

1. **The property language is the canonical verification surface.** A check is
   `(assert|assume|cover PROPERTY)` where `PROPERTY` is a boolean expression *or* a
   temporal property built from combinators (`(=> A B)` implication, `(within S N)`,
   later `eventually`/`until`/`throughout`/sequences) that lower to SVA property
   operators.
2. **Concurrent, clocked, reset-disabled is the default lowering** for the
   verification flavor: `assert property (@(posedge clk) disable iff (<reset>)
   (PROPERTY)) else $error(…)` under `` `ifndef SYNTHESIS `` (Verilog stays
   assertion-free). This is more correct for a synchronous FSM than immediate
   combinational checks (stable clock-edge sampling; no reset-phase false fires).
3. **`(contract (eventually S within N))` is removed entirely** (user decision,
   2026-06-02: "you even remove (contract …) altogether") — not kept as back-compat
   sugar. The property language replaces it: the bounded-eventually intent becomes a
   property like `(assert (=> <trigger> (within S N)))` → `trigger |-> ##[1:N] S`.
   Sequencing: the property language must first be able to express that intent
   (implication + `within`, and the transaction-point trigger anchor) **before**
   `contract` is deleted, so there is no capability gap. Then remove the `contract`
   clause, its monitor lowering (arm/pending/age/fail), and its tests/docs in one
   deliberate slice with golden review.
4. **Synthesizable monitor ≠ assertion.** The synthesizable fail-bit monitor that
   `contract` lowers to today is a *different artifact* (a real runtime checker)
   from a verification-only property. If that artifact is wanted it becomes an
   explicit **output mode** on a property (e.g. a `(monitor …)` modifier), not a
   second grammar. (Its current single-actor value is thin — the monitor's
   `assert` is not emitted there because the contract `schedule_report` is unwired.)

## Consequences / staging

- `ISF-ASSERT-CONCURRENT`: re-point the immediate-check emitter to clocked
  `assert/assume/cover property (@clk disable iff reset …)`; thread clock/reset.
  No new ISF language. (verilator simulates clocked boolean/implication
  properties under `--assert`; richer sequences are formal-tool territory.)
- `ISF-PROPERTY-IMPLICATION`: add `(=> A B)` (overlapping) + a next-cycle form
  (and `(within S N)` → `##[1:N]`) to an ISF property grammar lowering to SVA
  `|->`/`|=>`/`##`. The first real "capture SV-property intent at ISF level."
- Later: fold `(contract …)` onto the property language (sugar), with careful
  golden review; decide the synthesizable-monitor output-mode question then.
- Checkability is explicitly split: the *intent-capture* surface can be broad; the
  *CI-proven-with-verilator* surface stays boolean/implication; sequences/temporal
  are formal-tool (SymbiYosys/Jasper) checked.
