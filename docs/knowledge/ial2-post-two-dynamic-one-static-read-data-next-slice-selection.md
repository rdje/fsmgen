---
id: ial2-post-two-dynamic-one-static-read-data-next-slice-selection
title: Post two-dynamic/one-static read-data selector chooses same-cycle readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.362 select?"
  - "what comes after two-dynamic-plus-static single-beat read-data?"
  - "why is same-cycle request response readiness next?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.363?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, same-cycle, read-data, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.362|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.363|POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION|same-cycle request/response|release-and-recapture|onehot0_mixed_read_request' docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.362` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.363`, an audit of AXI generated dynamic
and mixed dynamic/static same-cycle request/response behavior after the
two-dynamic-plus-one-static read-data sibling shipped.

The selector changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, JSON, or HDL behavior.

The current selected dynamic/mixed response-demux and read-data chains now
cover the bounded public transaction sets, but their generated reports still
use onehot0 same-cycle request policy, active dynamic selected-ID uniqueness,
request no-active-same-ID checks, and static busy state. `.363` must decide
whether request plus generated completion, dynamic release-and-recapture, and
static release-and-recapture can be widened directly or require a smaller
prerequisite.

Broader arbitrary mixed cardinalities, dynamic same-ID queues, scoreboards,
queued/blocking policy, direct backend behavior, backend-language variants,
VHDL, and full AXI manager behavior remain later exact owners.
