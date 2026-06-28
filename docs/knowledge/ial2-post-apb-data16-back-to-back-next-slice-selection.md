---
id: ial2-post-apb-data16-back-to-back-next-slice-selection
title: APB protection back-to-back contract selected after data16 timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.626?"
  - "what APB owner follows data16 back-to-back behavior?"
  - "why select APB protection-only back-to-back before data16-protection?"
  - "do APB protection samples still carry back-to-back residue after .625?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.627 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, pprot, data16, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.626|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.627|protection back-to-back|apb_back_to_back_policy_deferred|temporary protected adjacent' docs/IAL2_POST_APB_DATA16_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.626` is a no-behavior selector after
`.625` shipped selected APB sideband-aware data16 back-to-back timing.

It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.627`, public contract
selection for a bounded APB sideband-aware protection back-to-back
timing-policy family, before implementation.

Live probes after `.625` show the 32-bit protection, data16-protection, and
protected multi-peripheral APB samples still have `protection_policy`, no
`back_to_back_policy`, and broad `apb_back_to_back_policy_deferred` residue.
A temporary protected adjacent-setup candidate is rejected by the current
no-policy timing guard, confirming that access-policy timing needs its own
contract.

Protection-only timing is selected before combined data16-protection timing
because it isolates register-local denied-read/denied-write semantics on the
already-shipped 32-bit sideband bus and avoids mixing narrower data16
`PSTRB width 2` behavior with protected adjacent setup in the first owner.
Combined data16-protection timing, multi-peripheral multi-register timing,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred after `.626`.
