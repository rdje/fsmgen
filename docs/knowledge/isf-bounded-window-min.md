---
id: isf-bounded-window-min
title: ISF bounded-window property supports a lower bound — (within B MIN MAX) -> ##[MIN:MAX]
answers:
  - "how do I express a min>1 bounded window / lower bound in an ISF assertion?"
  - "how do I say 'ack between 2 and 5 cycles after req' in ISF?"
  - "does ISF (within …) support a lower bound / a range / F[min,max]?"
  - "how does (within B MIN MAX) lower / what does ##[MIN:MAX] come from?"
date: 2026-06-04
status: current
tags: [isf, verification, properties, temporal, mtl]
evidence: docs/book/src/13d-control-flow.md (Delayed consequents); t/1418-isf-property-window-range.t; docs/tasks/ISF-PROPERTY-WINDOW-RANGE.md
reverify: prove -Iperl t/1418-isf-property-window-range.t
---

The bounded-window property combinator takes one **or two** bounds:

- `(within B N)` → `##[1:N] (B)` — `B` within `1..N` cycles (MTL `F[1,N]`).
- `(within B MIN MAX)` → `##[MIN:MAX] (B)` — `B` between `MIN` and `MAX` cycles later
  (MTL `F[MIN,MAX]`), with literal **`1 <= MIN <= MAX`**.

So `(assert (=> req (within ack 2 5)))` → `(req) |-> ##[2:5] (ack)`. Like every `##`
delay sequence it is **formal-only** (emitted under `` `ifdef FORMAL ``; verilator/yosys
skip it, so `--verify-hdl` stays green). `MIN = 0` **fails closed**: `[0,0]` is just the
overlapping `(=> A B)`, and `[0,N]` ("from here, eventually within N") is the
`(monitor (within S N))` anchored form — not a `|-> ##` consequent.

Shipped by `ISF-PROPERTY-WINDOW-RANGE.2` to close the `min > 1` MTL-window delta
SPECFORGE mines (it guarantees `1 <= MIN <= MAX`; see
`docs/SPECFORGE_FEEDBACK_RESPONSE.md`). Code home: [[isf-property-grammar-location]];
doc map: [[isf-verification-book-map]].
