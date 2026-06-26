---
id: ial1-expression-entry-guard-rendering-behavior
title: IAL1 expression entry guards now render valid generated FSM guard text
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.561 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.561?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.562?"
  - "are expression entry guards fixed?"
  - "is APB .ppif completer ready for direct implementation?"
  - "does (when EXPR (sample ...)) still emit ARRAY(...) guards?"
  - "can APB PSEL and not PENABLE setup guards lower through IAL1?"
date: 2026-06-26
status: current
tags: [ial1, isf, apb, task-tree]
evidence: docs/IAL1_EXPRESSION_ENTRY_GUARD_RENDERING_BEHAVIOR.md; docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1100-isf-sample-piggyback.t; t/1107-isf-when-body-ops.t; t/1244-isf-wait-clause-lowering.t; docs/book/src/13b-transactions.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1100-isf-sample-piggyback.t && scripts/run_with_ram_guard.sh -- prove -Iperl t/1107-isf-when-body-ops.t t/1244-isf-wait-clause-lowering.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.561` ships the IAL1 expression
entry-activation guard rendering repair. Generated `.fsm` sample enables and
entry transitions for first-clause `(when EXPR (sample ...))` now store
rendered `.fsm` expression text in `expr`, while keeping the structured
condition in `expr_ast` for internal analysis.

The APB-shaped setup detector `(when (& PSEL (! PENABLE)) (sample ...))` now
lowers each setup sample and the entry transition with `<(& PSEL (! PENABLE))`
instead of `ARRAY(...)`. Scalar `(on start (sample ...))` guards, existing
when-body behavior, and runtime-wait behavior remain covered by focused tests.

The IAL1 blocker selected by `.560` is fixed, so
`IAL2-FEATURE-COMPLETENESS-FRONTIER.562` is the next owner for bounded APB
`.ppif` completer direct implementation. `.561` itself does not add APB
`.ppif` completer parser/generator/sample/support behavior.
