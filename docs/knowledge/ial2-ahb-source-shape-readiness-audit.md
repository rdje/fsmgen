---
id: ial2-ahb-source-shape-readiness-audit
title: AHB source-shape readiness selects requester PPIF contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.695 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.696?"
  - "is AHB ready for implementation?"
  - "should AHB use .ppif or .ahb first?"
date: 2026-06-29
status: current
tags: [ial2, ahb, ppif, readiness, protocol-intent, task-tree]
evidence: docs/IAL2_AHB_SOURCE_SHAPE_READINESS_AUDIT.md; fsm/amba_requester.fsm; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.695|IAL2-FEATURE-COMPLETENESS-FRONTIER\.696|AHB requester \.ppif public contract selection|profile ahb|ahb-requester|source suffix.*\.ahb.*known IAL2 alias candidate|no parser behavior|no generator behavior' docs/IAL2_AHB_SOURCE_SHAPE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.695` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.696`, an AHB requester `.ppif` public
contract selection, as the next exact owner.

AHB is ready for contract selection, not implementation. The direct
`fsm/amba_requester.fsm` seed and current IAL2 infrastructure provide enough
evidence to select a bounded generic `.ppif` source shape, generated `.isf` and
`.fsm` review artifacts, reports, support accounting, diagnostics, validation,
and residue before behavior changes.

The first AHB source-shape work should use generic `.ppif`; `.ahb` remains a
future profile-alias candidate and must stay unsupported until a later exact
task-tree owner selects it.
