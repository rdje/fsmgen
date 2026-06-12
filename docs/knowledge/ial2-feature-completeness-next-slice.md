---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is read response-demux contract selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after auto-ID lifecycle residue alignment?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.37?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.36?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.35?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.34?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.33?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.32?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "what must happen before the next AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, auto-id, same-id, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md; docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.38|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.37|read response-demux|contract-selection|AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
transaction-envelope metadata, transaction event dispatch, concrete
transaction ID assertion, auto-ID lifecycle metadata, bounded auto-ID
request-ID drive, write response-demux metadata, IAL1 rule-pulse action,
generated write `BID` response-demux behavior, auto-ID lifecycle
report-residue alignment, and generated auto-ID same-ID avoidance, the next
active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.32` aligned the emitted report for
explicit generated write response demux. At that point,
`auto_id_lifecycle.residue` was `[same_id_ordering]`, while samples without
generated demux kept their existing `response_demux` residue. The later `.35`
slice removed that covered same-ID residue from generated response-demux
samples.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.33` selected `.34` as the AXI same-ID
ordering readiness audit because `same_id_ordering` was then the common
remaining ID/auto-ID/write-demux residue after generated write `BID` demux
and auto-ID residue alignment.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.34` decided whether the first same-ID
ordering step should be static/report classification, generated assertions,
allocator constraints, per-ID issue-order queues/scoreboards, or a smaller
IAL1/IAL0/SystemVerilog prerequisite before behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.34` selected the bounded generated
auto-ID same-ID avoidance path: pairwise active selected-ID assertions plus
machine-readable `same_id_ordering` report metadata. No new public syntax and
no IAL1/IAL0/SystemVerilog prerequisite are needed for that first
implementation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.35` shipped that first implementation.
The response-demux sample now reports empty `auto_id_lifecycle.residue`,
`response_demux.residue: [read_response_demux, read_data_interleaving,
bursts]`, and `same_id_ordering.generated_behavior: true`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.36` selected read response-demux
readiness as the next exact slice. `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`
audited whether bounded read `RID` response matching can be isolated safely.
It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.38`, a public
contract-selection slice, because the first read demux contract must decide
single-beat/non-burst scope, `response-event` semantics, read metadata
requirements, diagnostics, report shape, and residue before parser/report
metadata or behavior changes.

The full AXI manager is not implemented yet. Per-ID same-ID response queues,
authored concrete-ID same-ID ordering, read `RID` demux, read-data
interleaving/reassembly, bursts, queued/blocking policy, profile aliases,
full-manager syntax, and VHDL remain future exact-owner work.
VHDL stays deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is
feature-complete enough to reopen backend parity.
