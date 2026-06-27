---
id: ial2-post-apb-public-sync-next-slice-selection
title: Post APB public sync selector chooses named status-field contract
answers:
  - "what comes after APB public-surface sync?"
  - "what is the next APB slice after import-tree sync?"
  - "which task owns APB requester named status-field contract selection?"
  - "why choose APB named status fields before APB decode?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.576?"
date: 2026-06-27
status: current
tags: [ial2, apb, requester, status-field, task-tree]
evidence: docs/IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md; docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.575|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.576|apb_requester_status_field_deferred|APB requester named status-field|multi-peripheral APB interconnect/decode|APB back-to-back transfer policy' docs/IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.575` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.576`, APB requester named status-field
public contract selection.

The selector chooses named status fields because busy-capable APB requester and
composition reports now remove `apb_requester_busy_status_deferred` and keep
the narrower `apb_requester_status_field_deferred` residue. Multi-peripheral
decode, multi-register decode, sidebands/strobes, alternate widths, and
back-to-back transfer policy remain deferred because they change broader APB
topology, completer storage, bus semantics, or transfer scheduling.

`.576` is a contract-selection owner. It must not implement status-field
behavior or change parser, generator, sample, support-accounting, validation,
generated-artifact, JSON, HDL/runtime, direct backend, verification-output,
backend-language, AXI, APB, or VHDL behavior.
