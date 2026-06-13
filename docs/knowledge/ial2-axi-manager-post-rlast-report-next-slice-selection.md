---
id: ial2-axi-manager-post-rlast-report-next-slice-selection
title: Post-RLAST report selector chooses burst read-data contract selection
answers:
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.56?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.57?"
  - "why is AXI burst read-data behavior not implemented directly after RLAST report alignment?"
  - "what must be selected before AXI burst read-data reassembly?"
  - "can read-data be paired with response-scope burst-last?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, burst, rlast, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.57|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.58|POST_RLAST_REPORT_NEXT_SLICE_SELECTION|read_data\\.read capture_scope last-beat requires response_demux\\.read\\.response_scope burst_last|capture-scope|RRESP' docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.56` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.57`, public AXI burst read-data contract
selection, as the next exact owner.

Direct multi-beat read-data behavior is not selected yet. At this selector
boundary, the shipped `read-data` contract was still single-beat-only:
`capture_scope: single_beat`, `completion_source: response_demux`, and
`interleaving_policy: single_beat_by_rid`. The burst-last sample reported
generated `RLAST` completion behavior through `response_demux`, but had no
`read_data` contract.

The implementation still rejects the single-beat read-data contract when
paired with burst-last response demux:

```text
read_data requires response_demux.read.response_scope single_beat in this slice
```

`.57` must select the public source/report boundary before parser/report
metadata or generated behavior changes. The open contract choices include
capture scope beyond `single-beat`, completion source under last-beat response
demux, data/status/valid/length output binding shape, `ARLEN` or beat-count
or fixed bounded-depth policy, `RRESP` aggregation, interleaving/per-ID queue
policy, diagnostics, report keys, residue movement, validation gates,
rollback, docs, Knowledge Map, and VHDL deferral.

`.57` selected explicit last-beat read-data capture and advanced the frontier
to `.58`, parser/report metadata and static validation. Full multi-beat
reassembly remains deferred.

`.58` then shipped that parser/report metadata. Last-beat read-data metadata
can now be paired with generated `response_scope burst_last` response demux,
but generated last-beat `RDATA`/`RRESP` capture behavior remains deferred to
the `.59` readiness audit.
