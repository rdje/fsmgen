---
id: ial2-multiple-dynamic-recapture-contract-owner-selection
title: Multiple dynamic recapture selection starts with write BID contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.376 decide?"
  - "which multiple dynamic recapture owner is next?"
  - "why start multiple dynamic recapture with write BID?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.377?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-cycle, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RECAPTURE_SUPPORT_DETAIL_ALIGNMENT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.376|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.377|MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION|bounded_multi_dynamic_write_bid_demux_contract|multi_active_unique_dynamic_write_ids|onehot0_dynamic_write_request|request_no_active_same_id|response_unique_match' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.376` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.377`, public contract selection for
multiple all-dynamic write `BID` same-cycle release-and-recapture.

The selector starts with write `BID` because the existing multiple all-dynamic
write demux already owns per-transaction selected-ID/busy state, onehot0
request policy, active-ID uniqueness, request no-active-same-ID assertions,
response active/unique-match assertions, and completion-active assertions,
without the read-side `RLAST`, read-data, raw-`ARLEN`, runtime, or multi-beat
preservation consumers.

`.376` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
HDL, or runtime behavior. Read single-beat recapture, read burst-last
recapture, mixed dynamic/static recapture, static busy recapture, queues,
scoreboards, backend variants, VHDL, and full AXI manager behavior remain
later exact owners.
