# ISF-PROPERTY-IMPLICATION: temporal property operators (`(=> A B)`, `(within S N)`)

## Metadata

- Tree ID: `ISF-PROPERTY-IMPLICATION`
- Status: `active`
- Roadmap lane: `R14` (ISF — verification intent)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal (step 2 of `docs/decisions/0008`)

Give ISF a small **temporal-property grammar** so a check can express what SV
*properties* capture — starting with the workhorse, implication:

```lisp
(assert (=> req ack))              ;; req |-> ack          (overlapping, same cycle)
(assert (=> req (next ack)))       ;; req |=> ack          (next cycle)
(assert (=> req (within ack 3)))   ;; req |-> ##[1:3] ack  (within N cycles)
```

This is the first real "capture SV-property intent at the ISF level," and (with
the transaction-point trigger anchor) is what lets `(contract (eventually S within
N))` be removed (`0008`).

## Design

A check's `PROPERTY` is either a boolean expression (today) or a **property
combinator** over boolean leaves:

- `(=> ANT CONS)` — overlapping implication → `(ANT) |-> (CONS)`.
- `(next CONS)` inside the consequent (or `(=> A (next B))`) → `|=>` (next cycle).
- `(within SIG N)` as a consequent → `##[1:N] (SIG)` (literal `N >= 1`).

Property combinators do **not** fit the boolean `ExpressionBuilder` (which renders
`a < b`), so the property is kept as a small tagged tree distinct from the boolean
condition: the boolean *leaves* render via the existing CoreAST `to_systemverilog`;
the *combinators* render to SVA property syntax by a dedicated property renderer.

- **ISF lowerer / carrier**: detect a property combinator head (`=>` / `within` /
  `next`) in the check expression; carry the property structure (kind-tagged) in the
  `+assert` entry alongside (or instead of) the plain boolean.
- **FSMGenFull**: parse the property structure, parsing boolean leaves via
  `ExpressionBuilder`.
- **emitter**: render `assert property (@clk disable iff reset (PROPERTY)) …` where
  `PROPERTY` is the rendered combinator tree (builds on `ISF-ASSERT-CONCURRENT`).

## Slice plan

- `.1` select + design (this doc).
- `.2` overlapping implication `(=> A B)` → `A |-> B` end-to-end + tests + docs.
- `.3` next-cycle `|=>` and `(within S N)` → `##[1:N]`.
- (later, separate tree) the transaction-point trigger anchor + removing
  `(contract …)`.

## Non-Goals (for now)

- Full SVA sequences (`throughout`, `until`, `s_eventually`, multi-step `##`).
- Formal-only constructs not simulable by verilator (documented as intent-capture
  but not CI-proven).

## Acceptance Criteria

- `(assert (=> A B))` lowers to `assert property (@clk disable iff reset (A |-> B))`;
  verilator-lint + yosys clean; `verilator --binary --assert` shows the implication
  semantics (no fire when antecedent false; fire when antecedent true & consequent
  false); malformed forms fail closed; docs + tests; full suite green.

## Blockers

- Builds on `ISF-ASSERT-CONCURRENT` (the clocked-property emitter).

## Changelog

- `2026-06-02`: Created on the user's go-ahead for step (2) of `0008`.
