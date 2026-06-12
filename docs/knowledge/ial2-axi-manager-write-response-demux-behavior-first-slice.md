---
id: ial2-axi-manager-write-response-demux-behavior-first-slice
title: AXI write response-demux behavior is shipped for explicit write BID contracts
answers:
  - "is generated AXI write BID response demux shipped?"
  - "does response_demux.generated_behavior report true?"
  - "does response-demux still use authored completion inputs?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.30 ship?"
  - "what generated rules does AXI write response demux emit?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, bid, task-tree]
evidence: docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; ppif/axi_manager_capacity_status_response_demux.ppif; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md
reverify: rg -n 'response_demux|generated_behavior|axi0_w0_response_demux|generated_completion_signals|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.30' docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.30` shipped generated AXI write `BID`
response-demux behavior for explicit write response-demux contracts.

For the checked-in sample
`ppif/axi_manager_capacity_status_response_demux.ppif`, the generated IAL1
actor now declares the raw response event `axi0_write_complete` and write
response ID input `axi0_bid`, treats transaction completion names such as
`axi0_w0_complete` and `axi0_w1_complete` as generated pulse outputs, and
emits one guarded rule per auto-ID write transaction:

```text
(rule axi0_w0_response_demux
  (& axi0_write_complete axi0_w0_auto_id_busy_q
     (== axi0_bid axi0_w0_auto_id_q))
  (pulse axi0_w0_complete))
```

The generated `.fsm` lowers those completion signals through the existing
`<1` pulse-domain assignment path, so the capacity-release and auto-ID release
rules consume generated demux pulses rather than authored completion inputs.

The report keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and now sets
`response_demux.generated_behavior: true`. The report also lists generated
demux rules, generated completion signals, active/unique-match assertions, and
residue for read response demux, same-ID ordering, read-data interleaving, and
bursts. `id_response_rule_engine.residue` no longer includes `response_demux`
when explicit write demux behavior is present.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.31` selected `.32` to align the remaining
`auto_id_lifecycle.residue` report entry with this shipped behavior.

VHDL, read `RID` demux, same-ID response ordering queues, read-data
interleaving/reassembly, bursts, queued/blocking policy, profile aliases, and
full AXI manager behavior remain future exact-owner work.
