---
id: ial2-post-multiple-mixed-dynamic-static-read-rlast-recapture-next-slice-selection
title: Post two-static mixed read RLAST recapture selector picks three-static read audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.416 select?"
  - "why audit three-static mixed read recapture next?"
  - "what is the current three-static mixed read recapture baseline?"
  - "what remains deferred after the post multiple mixed read RLAST recapture selector?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, rlast, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.416|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.417|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|read_mixed_dynamic_static_response_demux_multi_static3\\.ppif|generated_multi_mixed_dynamic_static_read_demux|axi0_r3_static_request_not_busy|static_capture: absent|three-static read recapture' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.416` selects `.417`, a readiness audit
for one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture.

The selector chooses that audit because `.411` and `.415` shipped the
two-static read recapture family, `.322` already ships the three-static
single-beat read demux, and `.403` proves the mixed dynamic/static recapture
vocabulary can scale to three concrete static transactions on the write side.

A guarded baseline probe on
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`
started at 87.3% host memory against the 88% cutoff and produced a
46985-byte schedule report. The live report still uses
`generated_multi_mixed_dynamic_static_read_demux`, request-not-busy
assertions for `r0`/`r1`/`r2`/`r3`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`.

Direct implementation, three-static burst-last read recapture,
two-dynamic-plus-one-static read recapture, layered recapture-specific
consumer changes, validation retries, static-busy-only recapture, arbitration,
queues, scoreboards, backend variants, VHDL, and full-manager behavior remain
deferred until a later exact owner.
