---
id: ial2-mixed-dynamic-static-read-recapture-contract-selection
title: Mixed dynamic/static read single-beat recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.391 select?"
  - "what is the mixed dynamic/static read recapture contract?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.392 implement?"
  - "where are static mixed read recapture fields reported?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.391|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.392|MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION|mixed_dynamic_static_dynamic_read|mixed_dynamic_static_static_read|static_capture|axi0_r1_static_busy_release_recapture' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.391` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.392`, direct implementation of mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.

The selected contract preserves
`bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and
`generated_mixed_dynamic_static_read_demux`. Dynamic recapture fields should
live under `response_demux.read.dynamic_capture` with policy
`mixed_dynamic_static_dynamic_read` and rule
`axi0_r0_dynamic_id_release_recapture`.

Static concrete busy recapture should live under
`response_demux.read.static_capture` with policy
`mixed_dynamic_static_static_read` and rule
`axi0_r1_static_busy_release_recapture`. The selected assertion list replaces
the dynamic/static request-not-busy assertions with
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_static_request_idle_or_releasing`. `.391` changes no parser,
generator, PPIF sample, support accounting, tests, schedule/check/semantic
JSON, HDL, or runtime behavior.
