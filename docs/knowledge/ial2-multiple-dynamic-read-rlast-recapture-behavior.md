---
id: ial2-multiple-dynamic-read-rlast-recapture-behavior
title: Multiple dynamic read RLAST recapture is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.385 ship?"
  - "is multiple dynamic read RLAST same-cycle recapture generated?"
  - "what report fields identify multiple dynamic read RLAST recapture?"
  - "does multiple dynamic read RLAST recapture preserve read-data consumers?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, rlast, same-cycle, recapture, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_READINESS_AUDIT.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.385|AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR|generated_dynamic_demux_last_beat_completion|multi_active_unique_dynamic_read|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r0_dynamic_request_idle_or_releasing|axi0_r1_dynamic_request_idle_or_releasing|bounded_multi_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.385` ships same-cycle
release-and-recapture for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.

The public source syntax, support-accounting identity, generated last-beat
completion names, and `bounded_multi_dynamic_read_rid_rlast_demux_contract`
mode are unchanged. Each dynamic read transaction now reports
`release_recapture_rule: axi0_rN_dynamic_id_release_recapture`,
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read`,
`release_recapture_source: generated_dynamic_demux_last_beat_completion`, and
`release_recapture_transaction: rN`.

The recapture guard requires own admitted request, own generated final
`RID && RLAST` completion, own busy state, no sibling admitted request, and no
active sibling with the new `ARID`. Per-transaction request assertions changed
from request-not-busy to `axi0_rN_dynamic_request_idle_or_releasing`; onehot0,
no-active-same-ID, active-ID uniqueness, raw response active/unique-match, and
final completion-active assertions are preserved.

Scalar last-beat read-data, report-only raw-`ARLEN`, runtime beat-count/
`RLAST`, and multi-beat output-bank consumers remain preserved. Mixed
dynamic/static recapture, static busy recapture, queues, scoreboards, backend
variants, VHDL, and full AXI manager behavior remain future exact-owner work.
