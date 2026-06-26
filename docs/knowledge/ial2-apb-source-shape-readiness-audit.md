---
id: ial2-apb-source-shape-readiness-audit
title: APB has enough lower-layer evidence for source-shape contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.548 select?"
  - "is APB ready for an IAL2 source-shape contract?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.549?"
date: 2026-06-26
status: historical
tags: [ial2, apb, ppif, non-axi, task-tree]
evidence: docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md; docs/IAL2_PIF_PPI_GENERIC_CONTAINER_ALIAS_POLICY_SELECTION.md; docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; isf/apb_requester.isf; fsm/apb_requester.fsm; fsm/apb_completer.fsm; fsm/apb_tb.fsm; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.548|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.549|APB .*source-shape contract|must not accept \\.apb|lower-layer evidence|is not itself an IAL2 contract|APB \\.ppif source-shape public contract selection' docs/IAL2_APB_SOURCE_SHAPE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.548` found that APB has enough lower-layer
evidence for a public APB `.ppif` source-shape contract selection: the repo
has APB ISF, requester/completer FSM, composition, mdBook, and support-catalog
coverage.

That evidence was not yet an IAL2 contract. At `.548`, FSMGen still rejected
`.apb`, had no APB `.ppif` sample, and had no APB IAL2 report or
support-accounting identity.

`.548` selects `.549`, APB `.ppif` source-shape public contract selection
before any behavior change. `.549` must not accept `.apb` or add an APB sample.
