---
id: ial2-axi-manager-read-response-demux-metadata-first-slice
title: AXI read response demux metadata ships without generated read behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.39 ship?"
  - "does read response-demux generate RID demux behavior yet?"
  - "what is response_demux.read in the report?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.39?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, metadata, parser, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_response_demux.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.39|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.40|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.41|response_demux\\.read|generated_read_rid_demux|axi_manager_capacity_status_read_response_demux' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md ppif/axi_manager_capacity_status_read_response_demux.ppif docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.39` shipped parser/report metadata and
static validation for the bounded read response-demux contract. Public `.ppif`
sources may now use read, write, or mixed `response-demux` family arms. The
read arm requires `response-event`, `response-scope single-beat`, and
`transaction-completion generated`.

The report adds structural `response_demux.read` metadata:
`generated_behavior: false`, `response_event_role:
raw_accepted_read_response`, `response_scope: single_beat`,
`response_id_signal: axi0_rid`, `response_id_direction: generated_input`,
`transaction_completion_source: generated_demux`, read auto transactions, and
`generated_read_rid_demux` residue.

Generated read `RID` demux behavior is not shipped yet. Read transaction
completion events remain authored inputs, no read completion outputs or demux
rules are emitted, and HDL behavior is unchanged. The checked-in sample is
`ppif/axi_manager_capacity_status_read_response_demux.ppif`; support
accounting uses `intent.ppif_axi_manager_capacity_status_read_response_demux`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.40` later audited generated read `RID`
response-demux behavior readiness and selected direct bounded single-beat
implementation. `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` is the next
behavior owner.
