---
id: ial2-ahb-subordinate-public-contract-selection
title: AHB subordinate public contract selects ppif/ahb_lite_subordinate.ppif
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.711 select?"
  - "what is the first public IAL2 AHB subordinate contract?"
  - "what source path is selected for AHB subordinate IAL2?"
  - "what report schema and support identity are selected for AHB subordinate?"
  - "what comes after .711?"
  - "what did .712 later find about the .711 AHB subordinate contract?"
date: 2026-06-29
status: current
tags: [ial2, ahb, subordinate, contract-selection, ppif]
evidence: docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/IAL2_AHB_COMPLETER_SUBORDINATE_POST_SEED_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SEED_BEHAVIOR.md; fsm/ahb_lite_subordinate.fsm; docs/IAL2_AHB_SUBORDINATE_SEED_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_APB_COMPLETER_INTERCONNECT_CONTRACT_SELECTION.md; docs/IAL2_APB_COMPLETER_GENERATED_IAL1_SUBSTRATE_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.711|IAL2-FEATURE-COMPLETENESS-FRONTIER\.712|IAL2-FEATURE-COMPLETENESS-FRONTIER\.713|IAL2-FEATURE-COMPLETENESS-FRONTIER\.715|ppif/ahb_lite_subordinate\.ppif|ahb-subordinate|ahb_lite_subordinate\.(isf|fsm)|fsmgen\.ial2\.protocol_intent\.ahb_subordinate\.v1|intent\.ppif_ahb_lite_subordinate|HREADYOUT' docs/IAL2_AHB_SUBORDINATE_PUBLIC_CONTRACT_SELECTION.md docs/IAL2_AHB_SUBORDINATE_GENERATED_IAL1_SUBSTRATE_AUDIT.md docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md MEMORY.md docs/book/src/16c-ial2-ahb.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.711` selects the first public IAL2 AHB
subordinate contract without implementation.

The selected future source is `ppif/ahb_lite_subordinate.ppif`, with object
`(ahb-subordinate ahb_lite_subordinate ...)`, generated review artifacts
`ahb_lite_subordinate.isf` before `ahb_lite_subordinate.fsm`, report schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, support identity
`intent.ppif_ahb_lite_subordinate`, and coverage key
`ial2_ppif_ahb_lite_subordinate_pipeline_cli`.

The public object uses `ahb-subordinate` because the imported AHB source facts
and shipped direct seed use AHB subordinate terminology. The broader task-tree
phrase AHB completer/subordinate remains a lane label, not the selected public
object spelling.

`.711` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.712`, a no-behavior
generated-IAL1/IAL0/SV substrate audit, before any parser/generator/source
behavior implementation.

Later status: `.712` finds the generated transaction substrate ready for the
core AHB subordinate flow, but blocks implementation on generated-IAL1 output
default/reset semantics needed to prove reset/idle outputs such as
`HREADYOUT=1`. `.713` owns that no-behavior contract selection.

Later status: `.714` ships the generated-IAL1 output default/reset substrate,
and `.715` ships the selected public `ppif/ahb_lite_subordinate.ppif`
behavior through generated `ahb_lite_subordinate.isf` before generated
`ahb_lite_subordinate.fsm`.
