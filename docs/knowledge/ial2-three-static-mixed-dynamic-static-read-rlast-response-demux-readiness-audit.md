---
id: ial2-three-static-mixed-dynamic-static-read-rlast-response-demux-readiness-audit
title: Three-static mixed read RLAST demux readiness selects public contract work
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.324 decide?"
  - "what is next after three-static mixed read single-beat demux?"
  - "which owner selects the three-static mixed read RLAST contract?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, rlast, response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: bash knowledge-map/scripts/check_knowledge_map.sh
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.324` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.325`, public contract selection for
bounded one-dynamic plus three-concrete-static mixed dynamic/static read
burst-last `RID && RLAST` response-demux.

The audit changed no behavior. At `.324` time, three-static mixed read
single-beat `RID` response-demux already shipped, and the two-static mixed
read burst-last `RID && RLAST` report was list-shaped, but burst-last read
normalization still admitted only one dynamic plus one or two static reads.

The next contract-selection owner should decide whether to reuse
`response-demux.read` with `response-scope burst-last`, one one-bit
`last-signal`, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
and public sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.

Direct behavior was later shipped by `.326`. Read-data,
burst-length/runtime validation, multi-beat output banks,
two-dynamic-plus-static, general capped mixed sets, same-cycle, queue,
scoreboard, backend, and VHDL work remain future exact owners.
