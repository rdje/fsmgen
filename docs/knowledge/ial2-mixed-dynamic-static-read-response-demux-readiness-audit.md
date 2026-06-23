---
id: ial2-mixed-dynamic-static-read-response-demux-readiness-audit
title: Mixed dynamic/static read demux readiness selects single-beat contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.274 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.275?"
  - "what follows mixed dynamic/static read response-demux readiness?"
  - "what is the next IAL2 slice after mixed dynamic/static read readiness?"
  - "why is single-beat RID first for mixed dynamic/static read demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, readiness]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.274|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.275|MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT|bounded_mixed_dynamic_static_read_rid_demux_contract|response_demux\\.read dynamic ID matching requires every read transaction' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.274` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.275`, public contract selection for bounded
mixed dynamic/static read single-beat `RID` response-demux.

The current read demux path still fails closed when selected read transactions
mix dynamic and static/concrete IDs. Single-beat `RID` is the first safe mixed
read shape because it only needs raw accepted read response matching by `RID`;
burst-last `RID && RLAST`, read-data, raw `ARLEN`, runtime beat-count/`RLAST`,
and multi-beat output banks all add separate read-only coupling.

`.275` must select the public source shape, static-ID reservation policy,
onehot0 mixed read request policy, static busy-state ownership, report mode
such as `bounded_mixed_dynamic_static_read_rid_demux_contract`, diagnostics,
validation, rollback, docs, Knowledge Map impact, and explicit residue before a
later behavior slice changes parser, generator, samples, tests, JSON, or HDL.
