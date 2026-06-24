---
id: ial2-multiple-dynamic-write-recapture-contract-selection
title: Multiple dynamic write BID recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.377 decide?"
  - "what is the multiple dynamic write recapture contract?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.378 implement?"
  - "does multiple dynamic write recapture preserve onehot0 requests?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, write, same-cycle, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RECAPTURE_CONTRACT_OWNER_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.377|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.378|MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION|multi_active_unique_dynamic_write|axi0_w0_dynamic_id_release_recapture|axi0_w1_dynamic_id_release_recapture|axi0_write_dynamic_request_onehot0|axi0_w0_w1_write_dynamic_response_unique_match' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.377` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.378`, direct implementation of multiple
all-dynamic write `BID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`.

The selected contract preserves existing public syntax, support accounting,
`bounded_multi_dynamic_write_bid_demux_contract`, and onehot0 same-cycle
dynamic write request policy. Recapture is per transaction: a transaction can
capture a new `AWID` in the same cycle as its own generated matched-`BID`
completion while the response match still uses the pre-update selected ID.

The future implementation should add per-transaction
`release_recapture_rule`, `same_cycle_release_recapture_policy:
multi_active_unique_dynamic_write`, `release_recapture_source:
generated_dynamic_demux_completion`, and `release_recapture_transaction`
fields under `dynamic_capture.transactions[]`, replace per-transaction
request-not-busy assertions with idle-or-releasing assertions, and preserve
onehot0, no-active-same-ID, active-ID uniqueness, active-match, unique-match,
and completion-active assertions.

`.377` changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
HDL, or runtime behavior.
