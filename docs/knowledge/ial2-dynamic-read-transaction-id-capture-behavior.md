---
id: ial2-dynamic-read-transaction-id-capture-behavior
title: Dynamic read ID demux behavior is generated for one single-beat read
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.227 ship?"
  - "does FSMGen generate dynamic read RID matching?"
  - "what is the dynamic read ID demux behavior?"
  - "which PPIF sample covers dynamic read RID demux?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.227|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.228|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.229|DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR|POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION|axi_manager_capacity_status_dynamic_read_response_demux|bounded_dynamic_read_rid_demux_contract|matched_dynamic_id_single_beat' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_TRANSACTION_ID_CAPTURE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_ID_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.227` ships generated bounded single-beat
dynamic read transaction-ID capture and `RID` response matching.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif`. It uses one
transaction-local `(id dynamic)` read transaction plus explicit
`response-demux.read` with `response-scope single-beat` and generated
transaction completion.

The generated path captures admitted `ARID` into `axi0_r0_dynamic_id_q`, tracks
`axi0_r0_dynamic_busy_q`, matches raw accepted read responses with
`axi0_rid == axi0_r0_dynamic_id_q`, pulses `axi0_r0_complete`, and releases busy
from that generated completion.

Reports expose `bounded_dynamic_read_rid_demux_contract`,
`capture_event_source: admitted_dynamic_read_request`, and
`transaction_completion_semantics: matched_dynamic_id_single_beat`.

Dynamic read burst-last/`RLAST`, read-data routing, burst-length/runtime
validation, multiple dynamic read transactions, mixed dynamic/static demux,
same-cycle recapture, dynamic same-ID ordering, queues, scoreboards, direct
backend behavior, and VHDL remain future exact-owner work.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.228` selected `.229`, readiness audit for
dynamic read burst-last/`RLAST` transaction-ID capture and response matching.
