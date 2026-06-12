---
id: ial2-axi-manager-write-response-demux-metadata-first-slice
title: AXI write response-demux parser/report metadata is shipped without generated behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.27 ship?"
  - "is response-demux parser/report metadata implemented?"
  - "does response-demux generate BID demux behavior yet?"
  - "where is the generated response-demux behavior recorded?"
  - "what is the response_demux report shape?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; ppif/axi_manager_capacity_status_response_demux.ppif; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.27` shipped parser/report metadata and
static validation for the explicit AXI write response-demux opt-in:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The report additively emits `response_demux` with
`mode: bounded_write_bid_demux_contract`, `generated_behavior: false`, the
write response event, `response_id_signal: axi0_bid`,
`response_id_direction: generated_input`,
`transaction_completion_source: generated_demux`, the auto-ID write
transactions, and residue for generated write BID demux, read response demux,
same-ID ordering, read-data interleaving, and bursts.

This slice intentionally keeps generated `.isf`, `.fsm`, and HDL behavior
unchanged. It does not yet add `axi0_bid` as an IAL1 input for response demux
or emit generated demux rules.

The runnable public sample is
`ppif/axi_manager_capacity_status_response_demux.ppif`, with support
accounting entry `intent.ppif_axi_manager_capacity_status_response_demux`.

Historical note: `.27` was metadata-only. The generated write `BID`
response-demux behavior was later shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.30`; see
`docs/knowledge/ial2-axi-manager-write-response-demux-behavior-first-slice.md`.
