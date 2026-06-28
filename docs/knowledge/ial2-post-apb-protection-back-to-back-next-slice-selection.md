---
id: ial2-post-apb-protection-back-to-back-next-slice-selection
title: APB data16-protection back-to-back contract selection follows protected timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.629?"
  - "what APB owner follows protection back-to-back behavior?"
  - "why select APB data16-protection back-to-back next?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.630 select?"
  - "do APB data16-protection samples still carry back-to-back residue after .628?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.629|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.630|data16-protection back-to-back|apb_back_to_back_policy_deferred|temporary data16-protection adjacent' docs/IAL2_POST_APB_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.629` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.630`, public contract selection for a
bounded APB sideband-aware data16-protection back-to-back timing-policy
family, before any further behavior change.

Live probes after `.628` show the existing data16-protection standalone,
fixed-composition, and multi-peripheral samples are 16-bit, expose
`protection_policy`, have no `back_to_back_policy`, and retain broad
`apb_back_to_back_policy_deferred`. A temporary data16-protection adjacent
setup candidate still fails at the current selected-family timing guard.

Data16-protection is next because `.625` shipped selected data16 timing,
`.628` shipped selected protection timing, `.622` shipped sideband
multi-register timing, and `.603/.597` shipped the register-local `PPROT`
policy semantics. Multi-peripheral data16-protection timing, broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred after `.629`.
