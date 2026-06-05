---
id: isf-sampled-value-predicates
title: ISF verification properties support the SV sampled-value functions (stable/changed/rose/fell/past)
answers:
  - "how do I check a signal is stable or unchanged in an ISF assertion?"
  - "does ISF support $stable / $rose / $fell / $changed?"
  - "does ISF support $past in assertions?"
  - "how do I compare a signal to its previous sampled value in ISF?"
  - "how do I assert on a rising or falling edge in ISF?"
  - "how do I express 'data stable while valid' in ISF?"
  - "how do I write a stability or edge property in an assert/assume/cover?"
date: 2026-06-05
status: current
tags: [isf, verification, properties, sampled-value, sva]
evidence: docs/book/src/13d-control-flow.md (Sampled-value functions subsection); t/1417-isf-property-sampled-value.t; docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md
reverify: prove -Iperl t/1417-isf-property-sampled-value.t
---

Inside `(assert/assume/cover COND)`, `COND` may use the SystemVerilog sampled-value
functions in property expressions:

| ISF | SystemVerilog | meaning |
|---|---|---|
| `(stable SIG)`  | `$stable(SIG)`  | unchanged from the previous cycle |
| `(changed SIG)` | `$changed(SIG)` | differs from the previous cycle |
| `(rose SIG)`    | `$rose(SIG)`    | went `0 → 1` this cycle |
| `(fell SIG)`    | `$fell(SIG)`    | went `1 → 0` this cycle |
| `(past SIG)`    | `$past(SIG)`    | previous sampled value of `SIG` |
| `(past SIG N)`  | `$past(SIG, N)` | value sampled `N` cycles ago (`N >= 1`) |

The boolean predicates each take one signal; they stand alone or sit on either side of an implication —
`(assert (=> valid (stable data)))` → `(valid) |-> ($stable(data))`. Note
`(=> (rose req) ack)` ≡ `(after req ack)`, and `(stable s)` is the everyday
"unchanged" check (`$stable(s)` ≡ `s == $past(s)`). `past` is value-returning,
so use it inside a boolean expression: `(assert (== data (past data)))` →
`data == $past(data)`, or `(assume (== data (past data 2)))` →
`data == $past(data, 2)`.

They are **verilator-simulable** (not `##` delay sequences, so they stay under
`` `ifndef SYNTHESIS ``), keep their operand signal alive as a port, and are
**property-only** — a sampled-value head in a `when` guard / data RHS fails closed.
`past` accepts a signal, bit/slice, or aggregate leaf operand plus an optional positive
literal depth; malformed arity, non-signal operands, and nonpositive/nonliteral depths
fail closed. Shipped by `ISF-PROPERTY-SAMPLED-VALUE.2` for the boolean predicates and
`ISF-REMAINING-BROAD-FRONTIER.9.1` for value-returning `past`. To add another property
combinator, see [[isf-property-grammar-location]].
