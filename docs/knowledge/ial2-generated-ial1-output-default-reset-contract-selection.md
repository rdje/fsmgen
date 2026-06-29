---
id: ial2-generated-ial1-output-default-reset-contract-selection
title: Generated IAL1 output default/reset contract selects reset and default options
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.713 select?"
  - "what is the selected generated IAL1 output default/reset syntax?"
  - "what does AHB subordinate need before implementation after .713?"
  - "what comes after .713?"
  - "which task owns output default/reset implementation?"
date: 2026-06-29
status: current
tags: [ial1, ial2, isf, output-defaults, reset, ahb, contract-selection]
evidence: docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md; fsm/ahb_lite_subordinate.fsm; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.713|IAL2-FEATURE-COMPLETENESS-FRONTIER\.714|output default/reset|\\(output HREADYOUT \\(reset 1\\) \\(default 1\\)\\)|t/1476-isf-output-default-reset\.t' docs/IAL2_GENERATED_IAL1_OUTPUT_DEFAULT_RESET_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.713` selects generated-IAL1 output
default/reset semantics without implementation.

The selected source surface is additive metadata on actor-level interface
outputs:

```text
(output NAME [(width WIDTH)] [(type TYPE)] [(domain DOMAIN)]
             [(reset VALUE)] [(default VALUE)])
```

The first implementation supports non-negative integer literal values that fit
resolved positive integer widths. `(reset VALUE)` must lower to generated
`.fsm` `+size` reset metadata, while `(default VALUE)` must lower to
reviewable idle/quiescent output assignments.

`.713` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.714` as the implementation
owner for this substrate. AHB subordinate `.ppif` parser/generator/source
behavior remains deferred until the substrate is implemented and proven.
