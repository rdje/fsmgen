---
id: ial2-mixed-auto-id-queue-head-response-demux-behavior
title: Mixed auto-ID queue-head response-demux ships for bounded shapes
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.194 ship?"
  - "is mixed auto-ID plus concrete queue-head response-demux supported?"
  - "which PPIF samples cover mixed auto-ID plus queue-head response-demux?"
  - "does mixed auto-ID queue-head demux own the request ID output?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.194|MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR|mixed_auto_id_queue_head|generated_demux_and_queue_head_demux|read_single_beat_mixed_auto_id_same_id_queue_head_response_demux|read_burst_last_mixed_auto_id_same_id_queue_head_response_demux|write_mixed_auto_id_same_id_queue_head_response_demux' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.194` shipped bounded same-family mixed
auto-ID lifecycle plus concrete same-ID queue-head response-demux for public
read single-beat, read burst-last, and write response-demux-only shapes.

The public fixtures are:

- `ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux.ppif`
- `ppif/axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux.ppif`

The generated reports use mixed queue-head mode, set
`transaction_completion_source` to
`generated_demux_and_queue_head_demux`, generate completion outputs for both
auto-ID and concrete queue-head transactions, and build rules/assertions over
the combined response-demux state set.

The shared request-ID signal remains the auto-ID lifecycle generated output.
Concrete same-family transactions get generated concrete request-ID drive
rules, and effective ID-input reporting excludes that generated request-ID
output from `id_response_rule_engine.id_signal_inputs`.

Read-data consumption for mixed auto-ID plus queue-head response-demux,
group-local simultaneous enqueue widening, packed outputs, alternate burst
payload assembly, direct backend lowering, verification-output generation,
VHDL, and backend-language variants remain separately owned.
