---
id: ial2-post-multiple-mixed-dynamic-static-read-recapture-next-slice-selection
title: Post two-static mixed read recapture selector picks burst-last recapture audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.412 select?"
  - "why audit one dynamic plus two static mixed read burst-last recapture next?"
  - "what is the current two-static mixed read burst-last recapture baseline?"
  - "what remains deferred after the post multiple mixed read recapture selector?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.412|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.413|POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION|read_mixed_dynamic_static_response_demux_multi_static_burst_last|generated_multi_mixed_dynamic_static_read_demux_last_beat|axi0_r0_dynamic_request_not_busy|static_capture: absent|burst-last recapture' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.412` selects `.413`, a readiness audit
for one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture.

The selector chooses that audit because `.411` shipped the two-static
single-beat recapture shape, `.396` already ships the one-static burst-last
recapture template, and `.303` plus `.307`/`.310`/`.312`/`.314` already cover
the two-static burst-last demux and layered read-data/raw-`ARLEN`/runtime/
multi-beat consumers that must be preserved.

A guarded baseline probe on
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
started at 85.2% host memory against the 88% cutoff and produced a
44340-byte schedule report. The live report still uses
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, request-not-busy
assertions for `r0`/`r1`/`r2`, no `static_capture`, and no release-recapture
fields under `dynamic_capture.transactions[]`.

Direct implementation, three-static read recapture, two-dynamic-plus-one-static
read recapture, static-busy-only recapture, arbitration, queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain deferred until a
later exact owner.
