---
id: ial2-ahb-subordinate-generated-ial1-substrate-audit
title: AHB subordinate generated substrate audit blocks on output defaults
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.712 find?"
  - "why is AHB subordinate IAL2 implementation not ready after .712?"
  - "does generated IAL1 support AHB HREADYOUT reset defaults?"
  - "what comes after .712?"
  - "what gap blocks ppif/ahb_lite_subordinate.ppif implementation?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, generated-ial1, substrate-audit, output-defaults]
evidence: docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; fsm/ahb_lite_subordinate.fsm; docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md; perl/FSM/Adapter/ISF/Parser.pm; perl/FSM/Scheduler/ISF/ModuleEmitter.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.712|IAL2-FEATURE-COMPLETENESS-FRONTIER\.713|HREADYOUT|output default|generated-IAL1 output default/reset|ppif/ahb_lite_subordinate\.ppif' docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.712` finds that the generated-IAL1 path
can model the core AHB subordinate transaction flow, including `HSEL && HREADY`
acceptance, runtime `wait_cycles`, storage reset/update, mapped read/write
behavior, unsupported transfer/address/size branches, and two sequential ERROR
cycles.

The implementation is still blocked because the selected AHB subordinate
contract requires reset and idle outputs, especially `HREADYOUT=1`,
`HRESP=0`, and `HRDATA=0`. Current generated IAL1 carries output width/type/
domain metadata and scheduled transaction drives, but no selected
output default/reset metadata surface that proves those reset/idle values in
the generated `.fsm` review artifact.

`.712` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.713`, a no-behavior
contract-selection slice for generated-IAL1 output default/reset semantics,
before `ppif/ahb_lite_subordinate.ppif` implementation.
