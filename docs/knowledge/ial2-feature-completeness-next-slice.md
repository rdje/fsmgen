---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is post-mixed-response-demux selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.107?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.108?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.109?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.110?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.111?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.112?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.113?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.114?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.115?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.116?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.117?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.118?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.119?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.120?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.121?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.122?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.123?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.124?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.194?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.195?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID queue behavior implementation?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-feature-completeness-priority.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.194|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.195|MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR|same-family mixed auto-ID|concrete same-ID queue-head' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-feature-completeness-priority.md
---

The next IAL2 feature-completeness slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.195`, selector for the next exact slice
after bounded mixed auto-ID lifecycle plus concrete queue-head response-demux.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.194` shipped the direct bounded
response-demux-only implementation for public read single-beat, read
burst-last, and write fixtures. The selector must choose whether the next
owner targets mixed read-data consumption, group-local simultaneous enqueue
widening, write-family read-data diagnostics, packed burst-vector outputs,
alternate full burst payload assembly, report/static residue cleanup, direct
backend prerequisites, verification-output generation, VHDL/backend-language
variants, or another exact prerequisite before any behavior change.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.193` selected `.194` after confirming
that read single-beat, read burst-last, and write probes all failed closed at
the same local response-demux planner diagnostic, while adjacent shipped
auto-ID and queue-head samples strict-checked cleanly.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.192` selected `.193` after generated
multiple/mixed depth-3 runtime-validation multi-beat output-bank behavior
shipped in `.191`. The selected audit exists because generated auto-ID
response-demux and concrete same-ID queue-head response-demux are both shipped
on adjacent bounded shapes, while their same-family combination remains an
explicit fail-closed boundary that must audit completion ownership,
response-event fanout, report/residue shape, and support accounting before any
behavior change.

Historical notes from earlier queue-head frontier selection follow.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.106` shipped the first generated
same-ID queue behavior boundary for the public read burst-last depth-2 sample.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI same-ID write
queue-head behavior for one duplicate concrete write-ID group of two
transactions at computed depth 2. The generated match is write response event
plus concrete `BID` plus the compact one-hot queue head transaction bit, and
the existing auto-ID write demux path remains separate.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.109` selected `.110`, and `.110` has now
shipped generated AXI read `single-beat` same-ID queue-head behavior for one
duplicate concrete read-ID group of two transactions at computed depth 2. The
generated match is raw read response event plus concrete `RID` plus the
compact one-hot queue head transaction bit, without `RLAST`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.111` selected queue-head read-data
readiness as `.112`. `IAL2-FEATURE-COMPLETENESS-FRONTIER.112` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113`, generated single-beat read-data
capture for bounded read single-beat concrete same-ID queue-head demux.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.113` shipped that behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.114`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.114` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.115`, generated last-beat read-data
capture for the bounded read burst-last concrete same-ID queue-head demux
shape. `IAL2-FEATURE-COMPLETENESS-FRONTIER.115` shipped that behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.116`, the
selector for the next queue-head/read-data expansion.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.116` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.117` shipped that report-only behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.118`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.118` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.119`, generated queue-head
beat-count/`RLAST` runtime validation for the same bounded queue-head
last-beat read-data shape. `IAL2-FEATURE-COMPLETENESS-FRONTIER.119` shipped
that behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`
and advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.120`, the
next queue-head/read-data expansion selector. `IAL2-FEATURE-COMPLETENESS-FRONTIER.120`
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.121`, and `.121` shipped
generated multi-beat read-data output-bank behavior for the bounded read
burst-last concrete same-ID queue-head demux shape.

The already-covered public samples now report generated response demux,
generated same-ID ordering, `accepted_same_id_reuse: true`, and
`generated_queue_behavior: true` only for the bounded read burst-last, write,
and read single-beat depth-2 two-transaction shapes. Generated queue-head
read-data capture is now supported for the bounded read single-beat queue-head
shape and the bounded read burst-last queue-head last-beat shape. The
single-beat path reports `generated_queue_head_response_demux_completion_pulse`;
the last-beat path reports
`generated_queue_head_response_demux_last_beat_completion_pulse`. Existing
auto-ID read-data capture keeps its auto-ID completion-validity values.
The queue-head multi-beat path now reports `per_beat_output_bank`,
per-transaction valid masks and length outputs, scalar `RRESP` aggregation,
`read_data.residue: []`, and `response_demux.residue: []` for the bounded
sample. `IAL2-FEATURE-COMPLETENESS-FRONTIER.122` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.123`, readiness audit for multiple
independent read burst-last depth-2 concrete same-ID queue-head response-demux
groups. `IAL2-FEATURE-COMPLETENESS-FRONTIER.123` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.124`, generated read burst-last
response-demux-only queue-head behavior for two or more duplicate concrete
read-ID groups, each exactly two transactions at computed depth `2`. `.124`
must preserve the existing family-wide admitted-request onehot boundary and
must not claim read-data over multiple groups, same-family auto-ID, deeper
queues, write-family or single-beat multi-group behavior, packed outputs,
direct backend, or VHDL.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
