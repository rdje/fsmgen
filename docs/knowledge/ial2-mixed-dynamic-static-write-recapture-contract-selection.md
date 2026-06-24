---
id: ial2-mixed-dynamic-static-write-recapture-contract-selection
title: Mixed dynamic/static write recapture contract selected
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.388 select?"
  - "what is the mixed dynamic/static write recapture contract?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.389 implement?"
  - "where are static mixed write recapture fields reported?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, write, recapture, contract]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.388|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.389|MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION|mixed_dynamic_static_dynamic_write|mixed_dynamic_static_static_write|static_capture|axi0_w1_static_busy_release_recapture' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.388` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.389`, direct implementation of mixed
dynamic/static write `BID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`.

The selector preserves the existing public source syntax, support-accounting
identity, and `bounded_mixed_dynamic_static_write_bid_demux_contract` report
mode. It selects dynamic recapture fields under
`response_demux.write.dynamic_capture` with policy
`mixed_dynamic_static_dynamic_write`, and selects a new public
`response_demux.write.static_capture` block for the concrete static busy slot
with policy `mixed_dynamic_static_static_write`.

The selected implementation should emit `axi0_w0_dynamic_id_release_recapture`
and `axi0_w1_static_busy_release_recapture`, replace the dynamic and static
request-not-busy assertions with idle-or-releasing assertions, preserve mixed
request onehot0 and static-ID reservation assertions, and leave mixed read,
multiple mixed, queues, scoreboards, backend variants, VHDL, and full-manager
behavior to later exact owners. `.388` changes no behavior.
