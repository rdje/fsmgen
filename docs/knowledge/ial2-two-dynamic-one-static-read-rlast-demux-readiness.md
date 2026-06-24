---
id: ial2-two-dynamic-one-static-read-rlast-demux-readiness
title: Two-dynamic/one-static mixed read burst-last response-demux needs contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.345 decide?"
  - "what did the two-dynamic-plus-static mixed read burst-last readiness audit find?"
date: 2026-06-24
status: superseded
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.345|IAL2-FEATURE-COMPLETENESS-FRONTIER\.346|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_multi_mixed_dynamic_static_read_demux_last_beat|mixed_dynamic_static_read_rlast_demux_multi_dynamic' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.345` decided that bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux needs a public contract-selection slice before implementation.

The next task is `IAL2-FEATURE-COMPLETENESS-FRONTIER.346`. It should select
the exact public contract for planned sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last`,
and focused behavior label
`mixed_dynamic_static_read_rlast_demux_multi_dynamic`.

The selected contract is expected to reuse report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` and
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
with dynamic reads `r0`/`r1`, static read `r2` at ID `3`, one-bit last signal
`axi0_rlast`, raw `RID` beat ownership assertions without `RLAST`, and final
`RID && RLAST` generated completions.

A scratch RAM-guarded strict-check probe confirmed the current implementation
still fails closed for this shape: burst-last mixed dynamic/static read
matching currently supports one dynamic read plus one, two, or three concrete
static reads, not two dynamic reads plus one static read. No parser,
generator, PPIF sample, support-accounting, test, JSON, or HDL behavior
changed in `.345`.
