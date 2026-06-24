---
id: ial2-post-dynamic-read-rlast-recapture-next-slice-selection
title: Post dynamic read RLAST recapture selector chooses multiple dynamic readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.373 select?"
  - "what follows single-active dynamic read RLAST recapture?"
  - "why is multiple dynamic recapture readiness next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.374?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-cycle, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.373|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.374|POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|multiple all-dynamic same-cycle release-and-recapture|onehot0_dynamic_read_request|onehot0_dynamic_write_request|bounded_multi_dynamic_read_rid_rlast_demux_contract' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.373` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.374`, readiness audit for multiple
all-dynamic same-cycle release-and-recapture after the single-active dynamic
write, dynamic read single-beat, and dynamic read burst-last recapture
contracts shipped.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
HDL, or runtime behavior.

Multiple all-dynamic response-demux is the nearest broader recapture residue
because it still uses dynamic selected-ID/busy ownership, but it adds sibling
onehot0 request policy, active dynamic selected-ID uniqueness, request
no-active-same-ID checks, unique-match assertions, and burst-last raw
non-final-beat handling. `.374` must audit those contracts before any
multi-dynamic release-and-recapture behavior is selected.

Mixed dynamic/static recapture, static busy recapture, queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.
