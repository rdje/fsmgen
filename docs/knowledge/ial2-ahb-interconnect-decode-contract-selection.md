---
id: ial2-ahb-interconnect-decode-contract-selection
title: First AHB interconnect contract selects one requester and one subordinate
answers:
  - "what AHB interconnect contract was selected?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.721 select?"
  - "what is the first public AHB interconnect source path?"
  - "what support accounting will cover AHB interconnect PPIF?"
  - "why is AHB interconnect implementation not next?"
date: 2026-06-29
status: current
tags: [ial2, ahb, interconnect, decode, contract-selection, ppif, task-tree]
evidence: docs/IAL2_AHB_INTERCONNECT_DECODE_CONTRACT_SELECTION.md; docs/IAL2_AHB_INTERCONNECT_DECODE_READINESS_AUDIT.md; docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md; docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PPIF_BEHAVIOR.md; docs/IAL2_AHB_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_SUBORDINATE_PROFILE_ALIAS_BEHAVIOR.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.721|IAL2-FEATURE-COMPLETENESS-FRONTIER\.722|ppif/ahb_interconnect\.ppif|intent\.ppif_ahb_interconnect|t/1478-ial2-ahb-interconnect\.t|fsmgen\.ial2\.protocol_intent\.ahb_interconnect\.v1' docs/IAL2_AHB_INTERCONNECT_DECODE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.721` selects the first public AHB
interconnect/decode contract and routes the next slice to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.722`, a generated-substrate audit before
implementation.

The selected source is `ppif/ahb_interconnect.ppif` with explicit
`(profile ahb)`, one `(ahb-requester amba_requester ...)`, one
`(ahb-subordinate ahb_lite_subordinate ...)`, and one
`(ahb-interconnect ahb_tb ...)` object. The first topology has one requester,
one subordinate, one static address window, generated `ahb_interconnect.isf`
before `ahb_interconnect.fsm`, generated aggregate `ahb_tb.fsm`, and HDL entry
module `ahb_tb`.

The selected support identity is `intent.ppif_ahb_interconnect`, coverage key
`ial2_ppif_ahb_interconnect_pipeline_cli`, source kind `ppif`, and focused
test `t/1478-ial2-ahb-interconnect.t`. Direct implementation is deferred until
`.722` audits generated support for `HREADY` aggregation, `HRESP` widening,
`HSEL` decode, local address translation, and interconnect-owned unmapped
two-cycle ERROR.
