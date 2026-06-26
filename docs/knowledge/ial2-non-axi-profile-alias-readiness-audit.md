---
id: ial2-non-axi-profile-alias-readiness-audit
title: Non-AXI aliases need taxonomy and evidence before contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.545 find?"
  - "are non-AXI profile aliases ready for implementation?"
  - "what follows the non-AXI profile-alias readiness audit?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.546?"
date: 2026-06-26
status: historical
tags: [ial2, profile-alias, non-axi, readiness]
evidence: docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.545|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.546|taxonomy and evidence prerequisite|no non-AXI profile-alias support-accounted fixture|not a protocol suffix contract|must not accept any new suffix' docs/IAL2_NON_AXI_PROFILE_ALIAS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.545` found that non-AXI protocol aliases
were not ready for implementation or public contract selection at that point.
The CLI rejected `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s`
before PPIF parsing; PPIF profile-alias validation was `.axi`-specific; and
there was no non-AXI profile-alias support-accounted fixture.

`.545` selects `.546`, a taxonomy and evidence prerequisite that must separate
generic-container candidates `.pif`/`.ppi` from protocol-profile aliases and
must not accept any new suffix or change behavior.

Current `.apb` behavior after `.554` is tracked by
`docs/knowledge/ial2-apb-profile-alias-behavior.md`.
