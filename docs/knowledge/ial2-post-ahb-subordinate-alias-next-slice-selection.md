---
id: ial2-post-ahb-subordinate-alias-next-slice-selection
title: AHB interconnect/decode readiness follows shipped requester and subordinate aliases
answers:
  - "what comes after AHB subordinate .ahb shipped?"
  - "which AHB residue is next after .718?"
  - "is AHB interconnect/decode next after requester and subordinate entrypoints?"
  - "why not AHB optional signals after subordinate alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.719 select?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, subordinate, selector, task-tree]
evidence: docs/IAL2_POST_AHB_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; ppif/ahb_requester.ppif; ppif/ahb_requester.ahb; ppif/ahb_lite_subordinate.ppif; ppif/ahb_lite_subordinate.ahb; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.719|IAL2-FEATURE-COMPLETENESS-FRONTIER\.720|AHB interconnect/decode readiness|ahb_interconnect' docs/IAL2_POST_AHB_SUBORDINATE_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.719` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.720`, a no-behavior AHB
interconnect/decode readiness audit, after the requester and subordinate
`.ppif` and `.ahb` entrypoints shipped.

The reason is that both endpoint prerequisites now exist:
`ppif/ahb_requester.ppif`, `ppif/ahb_requester.ahb`,
`ppif/ahb_lite_subordinate.ppif`, and `ppif/ahb_lite_subordinate.ahb`. Live
schedule probes still show requester-side `ahb_interconnect_decode_deferred`
and subordinate-side `ahb_interconnect_generation_deferred` residue, so `.720`
must audit topology/decode readiness and residue-key convergence before any
fabric behavior.

Optional AHB signals, burst `SEQ`, byte-lane/narrow-transfer behavior, legacy
two-bit `HRESP`, direct backend behavior, verification-output generation,
backend-language variants, AXI, APB, and VHDL remain later exact owners.
