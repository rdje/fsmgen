---
id: ial2-post-mixed-dynamic-static-read-burst-last-same-id-issue-order-queue-next-slice-selection
title: Post mixed dynamic/static read RID/RLAST issue-order queue selects public surface synchronization
answers:
  - "what is next after mixed dynamic/static read RID/RLAST same-ID issue-order queue?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.510 select?"
  - "is mixed read-data next after the mixed RID/RLAST issue-order queue?"
  - "why is public .ppif surface synchronization next after .509?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, read-rid, rlast, downstream, manifest, mdbook, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/knowledge/downstream-consumer-contract-lockstep.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/book/src/11-extensions-and-embedding.md; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.510|IAL2-FEATURE-COMPLETENESS-FRONTIER\.511|POST_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|generated mixed dynamic/static same-ID issue-order queue|language_surface\.file_surfaces|docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md|docs/book/src/11-extensions-and-embedding.md' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.510` selects `.511`, public `.ppif`
downstream-contract, capability-manifest, and mdBook surface synchronization
after `.509` shipped generated mixed dynamic/static read burst-last `RID &&
RLAST` same-ID `issue-order-queue` behavior.

Mixed read-data over the generated mixed queue is not selected yet. The
selector found a prerequisite public-surface gap: the downstream integration
handoff, public interface contract, embedding chapter, and
`language_surface.file_surfaces` `.ppif` manifest boundary do not yet advertise
the generated mixed dynamic/static same-ID issue-order queue chain shipped by
`.503`, `.506`, and `.509`.

`.511` should synchronize those public summaries and explicit deferrals without
changing parser/generator behavior, PPIF samples, support accounting, generated
artifacts, schedule/check/semantic JSON, HDL/runtime, backend behavior,
verification output, external converter dependencies such as `sv2v`, or VHDL.
