---
id: isf-while-when-repeat-local-do
title: ISF while-then-when repeat-body local do support
answers:
  - "does ISF support local do inside a repeat under while then when?"
  - "can while -> when -> repeat -> do lower in ISF?"
  - "is loop-plus-branch repeat-body local do shipped?"
  - "which loop-plus-branch repeat-body do subset is supported?"
date: 2026-06-10
status: current
tags: [isf, control-flow, repeat, do, scheduling]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1379-isf-loop-contained-repeat-body-local-do.t; t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t; t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t; docs/book/src/13d-control-flow.md; docs/book/src/13k-isf-feature-support-matrix.md; docs/ISF_SPEC.md
reverify: prove -Iperl t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t t/1379-isf-loop-contained-repeat-body-local-do.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t
---

ISF accepts a plain local `(do child)` inside a `(repeat ...)` reached through
one `while` body and one nested `when` body:

```lisp
(while c1
  (when c2
    (repeat n
      (do child))))
```

The child must be local to the scheduled parent. The `while` guard enters the
nested `when`, the `when` guard enters `repeat_init`, the local `do` asserts the
child start and waits for the child done pulse, and `repeat_check` either
re-runs the child or returns to the `while` re-test.

Generated `do`, `spawn`, cross-domain, `(bind ...)`, `(domain ...)`,
`until -> when`, nested `switch`, and extra loop nesting in the same
loop-plus-branch family remain fail-closed.
