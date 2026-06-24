---
id: ial2-multiple-dynamic-recapture-readiness-audit
title: Multiple dynamic recapture audit selects support-detail cleanup first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.374 decide?"
  - "is multiple dynamic recapture ready for contract selection?"
  - "why is support detail cleanup before multiple dynamic recapture?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.375?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-cycle, recapture, readiness, audit]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.374|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.375|MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT|without release-and-recapture|same-cycle recapture outside single-active dynamic write BID demux and single-active dynamic read single-beat RID demux|onehot0_dynamic_read_request|onehot0_dynamic_write_request' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.374` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.375`, generated support-detail prose
alignment for the shipped single-active dynamic read burst-last
release-and-recapture behavior, before selecting a multiple-dynamic recapture
contract.

The audit changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
HDL, or runtime behavior.

Guarded probes confirmed the multiple all-dynamic write, read single-beat, and
read burst-last samples still report onehot0 request policy, active dynamic ID
uniqueness, request no-active-same-ID checks, response unique-match assertions,
and request-not-busy assertions. The implementation only emits
release-recapture rules for states marked with the single-active dynamic
recapture policies.

The audit found stale generated support-detail prose that still says
single-active dynamic read burst-last `RID/RLAST` matching is supported
without release-and-recapture and still lists same-cycle recapture as future
outside only single-active dynamic write and read single-beat demux. `.375`
should align that support text before the next multiple-dynamic recapture
contract selection.
