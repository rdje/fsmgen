---
id: ial2-multiple-dynamic-read-recapture-contract-selection
title: Multiple dynamic read single-beat recapture contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.380 select?"
  - "what is the contract for multiple dynamic read same-cycle recapture?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.381 implement?"
  - "what release recapture fields are planned for multiple dynamic read?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, read, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.380|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.381|MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION|multi_active_unique_dynamic_read|generated_dynamic_demux_completion|axi0_r0_dynamic_id_release_recapture|axi0_r1_dynamic_id_release_recapture|axi0_r0_dynamic_request_idle_or_releasing|axi0_r1_dynamic_request_idle_or_releasing' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.380` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.381`, direct implementation of multiple
all-dynamic read single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif`.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, HDL, or runtime behavior.

The selected implementation should preserve
`bounded_multi_dynamic_read_rid_demux_contract`, onehot0 request policy,
generated response-demux rules, generated completion pulses, active-ID
uniqueness, request no-active-same-ID, response active/unique-match, and
completion-active assertions. It should add per-transaction
`release_recapture_rule`, `same_cycle_release_recapture_policy:
multi_active_unique_dynamic_read`, `release_recapture_source:
generated_dynamic_demux_completion`, and `release_recapture_transaction`, and
replace per-transaction request-not-busy assertions with idle-or-releasing
assertions.

Scalar single-beat multiple dynamic read-data remains a preservation consumer
over generated completion pulses; burst-last `RID && RLAST`, raw `ARLEN`,
runtime validation, multi-beat output banks, mixed dynamic/static recapture,
static busy recapture, queues, scoreboards, backend variants, VHDL, and
full-manager behavior remain future owners.
