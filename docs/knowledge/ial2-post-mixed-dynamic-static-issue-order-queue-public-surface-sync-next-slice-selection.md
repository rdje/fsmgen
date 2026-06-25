---
id: ial2-post-mixed-dynamic-static-issue-order-queue-public-surface-sync-next-slice-selection
title: Post public mixed queue surface sync selects mixed queue read-data readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.512 select?"
  - "what is next after public mixed dynamic/static issue-order queue surface sync?"
  - "why audit mixed read-data over generated mixed dynamic/static issue-order queues next?"
  - "is raw ARLEN next after public mixed queue surface sync?"
  - "did .512 change parser or generator behavior?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-data, selector, mdbook]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.512|IAL2-FEATURE-COMPLETENESS-FRONTIER\.513|POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION|read-data routing over generated mixed dynamic/static read same-ID `?issue-order-queue`? completion pulses|generated_mixed_dynamic_static_issue_order_queue_demux|No parser, generator, PPIF sample, support-accounting catalog' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.512` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.513`, readiness audit for scalar
read-data routing over generated mixed dynamic/static read same-ID
`issue-order-queue` completion pulses.

Read-data is next because `.503`, `.506`, and `.509` generated mixed
dynamic/static write/read same-ID queue behavior, `.511` synchronized public
surfaces, and the remaining closest user-visible residue is scalar read-data
over the generated mixed read queue completion sources
`generated_mixed_dynamic_static_issue_order_queue_demux` and
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`.

`.512` changes no parser or generator behavior, PPIF samples,
support-accounting catalog, generated artifacts, schedule/check/semantic JSON,
tests, HDL/runtime behavior, backend behavior, external converter behavior,
verification output, or VHDL behavior. Raw `ARLEN`, runtime validation, and
multi-beat output banks over generated mixed dynamic/static issue-order queues
remain later exact owners.
