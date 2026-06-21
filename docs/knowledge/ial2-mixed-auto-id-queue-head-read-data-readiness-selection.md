---
id: ial2-mixed-auto-id-queue-head-read-data-readiness-selection
title: Mixed auto-ID queue-head read-data is selected for readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.195 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.196?"
  - "is mixed read-data over mixed auto-id queue-head response-demux supported?"
  - "what follows mixed auto-ID queue-head response-demux?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, read-data, readiness]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.195|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.196|mixed read-data consumption|generated_demux_and_queue_head_demux|_read_data_response_demux_transaction_coverage' docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.195` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.196`, readiness audit for mixed read-data
consumption over same-family mixed auto-ID lifecycle plus concrete same-ID
queue-head response-demux.

Mixed read-data over that mixed response-demux source is not shipped yet.
`.194` shipped response-demux-only behavior with
`transaction_completion_source: generated_demux_and_queue_head_demux`; `.196`
must audit the read-data transaction/completion binding before any generated
read-data behavior changes.

The audit exists because `_read_data_response_demux_transaction_coverage`
still has separate queue-head and auto-ID coverage paths. The mixed source
needs an explicit selected contract for whether the first behavior covers read
single-beat scalar `RDATA`/`RRESP`, read burst-last scalar last-beat
`RDATA`/`RRESP`, both, or a smaller prerequisite.
