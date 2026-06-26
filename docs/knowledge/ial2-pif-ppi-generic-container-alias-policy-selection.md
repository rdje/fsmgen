---
id: ial2-pif-ppi-generic-container-alias-policy-selection
title: PIF and PPI remain unsupported historical generic-container spellings
answers:
  - "what is the .pif .ppi generic-container alias policy?"
  - "does FSMGen accept .pif or .ppi?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.547 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.548?"
date: 2026-06-26
status: current
tags: [ial2, pif, ppi, ppif, apb, non-axi, task-tree]
evidence: docs/IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md; docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; bin/fsmgen; perl/FSM/Support/LanguageSurfaceSection.pm; isf/apb_requester.isf; fsm/apb_requester.fsm; fsm/apb_completer.fsm; fsm/apb_tb.fsm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.547|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.548|explicitly unsupported historical generic-container spellings|APB IAL2 source-shape readiness audit|must not accept \\.apb|does not create another suffix|only shipped generic IAL2 container' docs/IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.547` keeps `.pif` and `.ppi` explicitly
unsupported historical generic-container spellings. `.ppif` remains the only
shipped generic IAL2 container; `.pif` and `.ppi` are not accepted aliases.

`.547` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.548`, an APB IAL2
source-shape readiness audit. `.548` must not accept `.apb`, add an APB
`.ppif` sample, or change parser/generator behavior.
