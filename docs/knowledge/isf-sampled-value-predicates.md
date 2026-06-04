---
id: isf-sampled-value-predicates
title: ISF verification properties support the SV sampled-value functions (stable/changed/rose/fell)
answers:
  - "how do I check a signal is stable or unchanged in an ISF assertion?"
  - "does ISF support $stable / $rose / $fell / $changed?"
  - "how do I assert on a rising or falling edge in ISF?"
  - "how do I express 'data stable while valid' in ISF?"
  - "how do I write a stability or edge property in an assert/assume/cover?"
date: 2026-06-04
status: current
tags: [isf, verification, properties, sampled-value, sva]
evidence: docs/book/src/13d-control-flow.md (Sampled-value predicates subsection); t/1417-isf-property-sampled-value.t; docs/tasks/ISF-PROPERTY-SAMPLED-VALUE.md
reverify: prove -Iperl t/1417-isf-property-sampled-value.t
---

Inside `(assert/assume/cover COND)`, `COND` may use the SystemVerilog sampled-value
functions as property leaves:

| ISF | SystemVerilog | meaning |
|---|---|---|
| `(stable SIG)`  | `$stable(SIG)`  | unchanged from the previous cycle |
| `(changed SIG)` | `$changed(SIG)` | differs from the previous cycle |
| `(rose SIG)`    | `$rose(SIG)`    | went `0 → 1` this cycle |
| `(fell SIG)`    | `$fell(SIG)`    | went `1 → 0` this cycle |

Each takes one signal; they stand alone or sit on either side of an implication —
`(assert (=> valid (stable data)))` → `(valid) |-> ($stable(data))`. Note
`(=> (rose req) ack)` ≡ `(after req ack)`, and `(stable s)` is the everyday
"unchanged" check (`$stable(s)` ≡ `s == $past(s)`).

They are **verilator-simulable** (not `##` delay sequences, so they stay under
`` `ifndef SYNTHESIS ``), keep their operand signal alive as a port, and are
**property-only** — a sampled-value head in a `when` guard / data RHS fails closed.
Shipped by `ISF-PROPERTY-SAMPLED-VALUE.2`. Value-returning `(past …)` is deferred.
To add another property combinator, see [[isf-property-grammar-location]].
