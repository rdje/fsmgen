---
id: ial2-ahb-requester-ppif-public-contract-selection
title: First AHB requester PPIF contract selected the .697 implementation owner
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.696 decide?"
  - "what is the first AHB PPIF contract?"
  - "what should ppif/ahb_requester.ppif contain?"
  - "is .ahb accepted after IAL2-FEATURE-COMPLETENESS-FRONTIER.696?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.697?"
date: 2026-06-29
status: current
tags: [ial2, ahb, ppif, contract, protocol-intent, task-tree]
evidence: docs/IAL2_AHB_REQUESTER_PPIF_PUBLIC_CONTRACT_SELECTION.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.696|IAL2-FEATURE-COMPLETENESS-FRONTIER\.697|ppif/ahb_requester\.ppif|profile ahb|ahb-requester amba_requester|protocol_intent\.ahb_requester|fsmgen\.ial2\.protocol_intent\.ahb_requester\.v1|intent\.ppif_ahb_requester|source_kind: ppif|\.ahb remains unsupported|bounded AHB requester' docs/IAL2_AHB_REQUESTER_PPIF_PUBLIC_CONTRACT_SELECTION.md docs/IAL2_AHB_REQUESTER_PPIF_BEHAVIOR.md docs/book/src/16c-ial2-ahb.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.696` selected the first AHB requester
generic `.ppif` public contract and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.697` as its implementation owner. The
source is `ppif/ahb_requester.ppif`, with `(profile ahb)` and one
`(ahb-requester amba_requester ...)` object.

The selected contract requires clock/reset, `local-command`, `local-status`,
`bus`, `burst`, `transfer`, and `response` clauses that mirror the bounded
direct `fsm/amba_requester.fsm` requester seed. The selected generated review
artifacts are `amba_requester.isf` and `amba_requester.fsm`; the HDL module is
`amba_requester`.

The selected report kind/schema are `protocol_intent.ahb_requester` and
`fsmgen.ial2.protocol_intent.ahb_requester.v1`. The selected support entry is
`intent.ppif_ahb_requester` with `source_kind: ppif`.

`.696` itself did not implement behavior and did not add the public sample;
`.697` later implemented the bounded AHB requester `.ppif` surface. `.ahb`
remains unsupported.
