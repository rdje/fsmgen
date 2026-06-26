---
id: ial2-protocol-neutral-valid-ready-ppif-readiness-audit
title: Protocol-neutral Valid-Ready PPIF needs a public vocabulary contract first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.529 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.530?"
  - "can FSMGen ship a protocol-neutral Valid-Ready PPIF sample immediately?"
  - "why not add a non-AXI Valid-Ready PPIF sample directly?"
  - "is Valid-Ready currently protocol-neutral in implementation?"
date: 2026-06-26
status: current
tags: [ial2, ppif, protocol-platform, valid-ready, profile, axi, task-tree]
evidence: docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md; docs/IAL2_POST_GUARDRAIL_NEXT_SLICE_SELECTION.md; docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md; docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; ppif/axi_aw_valid_ready.ppif; ppif/axi_aw_w_valid_ready_bundle.ppif; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.529|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.530|Protocol-Neutral Valid-Ready PPIF|profile and source-vocabulary|AXI Valid-Ready IAL2 contract|axi_aw_valid_ready|axi_aw_w_valid_ready_bundle' docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_PPIF_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm perl/FSM/Adapter/IAL2/PPIF.pm ppif/axi_aw_valid_ready.ppif ppif/axi_aw_w_valid_ready_bundle.ppif docs/knowledge/ial2-protocol-neutral-valid-ready-ppif-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.529` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.530`, public contract selection for a
protocol-neutral/non-AXI Valid-Ready `.ppif` profile and source-vocabulary
boundary.

A protocol-neutral/non-AXI Valid-Ready sample should not be added directly on
the current behavior. `.ppif` is generic IAL2 and AXI is only the first
shipped profile/example, but the current Valid-Ready implementation path still
accepts only AXI profiles and AXI channel families. The next owner must select
the public vocabulary contract before parser, generator, sample,
support-accounting, or report changes.
