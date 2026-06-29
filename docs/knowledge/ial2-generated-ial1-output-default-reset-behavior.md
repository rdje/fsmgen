---
id: ial2-generated-ial1-output-default-reset-behavior
title: Generated IAL1 output default/reset behavior ships parser, lowering, and HDL coverage
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.714 implement?"
  - "how do generated IAL1 output reset/default options lower?"
  - "does generated IAL1 support output reset_value/default_value metadata?"
  - "what task owns AHB subordinate implementation after output defaults?"
date: 2026-06-29
status: current
tags: [ial1, ial2, isf, output-defaults, reset, ahb, behavior]
evidence: docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR.md; docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Support/ISFPublicInterfaceContract.pm; t/1476-isf-output-default-reset.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/13h-lowering-reference.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1476-isf-output-default-reset.t && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.714|IAL2-FEATURE-COMPLETENESS-FRONTIER\.715|output default/reset|reset_value|default_value|<-\s+\(ready>' docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/13h-lowering-reference.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/LoweringIR.pm t/1476-isf-output-default-reset.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.714` implements generated-IAL1 actor
interface output `(reset VALUE)` and `(default VALUE)` metadata.

The parser accepts non-negative integer literal values on actor-level outputs
with resolved positive integer widths. It publishes `reset_value` and
`default_value` on output entries, rejects input/malformed/negative/too-wide
values, and leaves type-referenced or unresolved-width outputs deferred.

Lowering emits `(reset VALUE)` into generated `.fsm` `+size` reset metadata.
It emits `(default VALUE)` as idle/quiescent `<- (output> VALUE)` assignments
in generated transaction entry states, skipping outputs already assigned in
that state and preserving explicit named-drive behavior.

The next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.715`, public IAL2 AHB
subordinate implementation over the now-shipped output default/reset
substrate.
