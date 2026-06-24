---
id: ial2-multiple-dynamic-read-recapture-behavior
title: Multiple dynamic read RID recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.381 ship?"
  - "is multiple dynamic read same-cycle recapture generated?"
  - "what is multi_active_unique_dynamic_read?"
  - "which assertions changed for multiple dynamic read recapture?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, same-cycle, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.381|AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR|multi_active_unique_dynamic_read|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r0_dynamic_request_idle_or_releasing|axi0_r1_dynamic_request_idle_or_releasing|bounded multiple all-dynamic read single-beat RID response matching including same-cycle release-and-recapture' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.381` ships same-cycle
release-and-recapture for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`.

The public source syntax, support-accounting identity, generated completion
names, and `bounded_multi_dynamic_read_rid_demux_contract` report mode are
unchanged. Each dynamic read transaction now has its own
`axi0_rN_dynamic_id_release_recapture` rule and reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` under
`dynamic_capture.transactions[]`.

The recapture guard requires own admitted request, own generated matched
single-beat `RID` completion, own busy state, no sibling admitted request, and
no active sibling with the new `ARID`. Per-transaction request assertions
changed from request-not-busy to
`axi0_rN_dynamic_request_idle_or_releasing`; onehot0 request policy,
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions are preserved.

Multiple dynamic read burst-last recapture, mixed dynamic/static recapture,
static busy recapture, request arbitration beyond onehot0, queues, scoreboards,
backend variants, VHDL, and full AXI manager behavior remain future
exact-owner work.
