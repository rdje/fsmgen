---
id: ial2-mixed-dynamic-static-issue-order-queue-public-surface-sync
title: Public PPIF surfaces advertise generated mixed dynamic/static same-ID issue-order queues
answers:
  - "does the public .ppif contract advertise mixed dynamic/static same-ID issue-order queues?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.511 sync?"
  - "does the capability manifest advertise mixed dynamic/static issue-order queue coverage?"
  - "did .511 change parser or generator behavior?"
date: 2026-06-26
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, mixed-dynamic-static, same-id-ordering, issue-order-queue, downstream, manifest, mdbook]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; docs/book/src/11-extensions-and-embedding.md; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.511|MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC|generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID issue-order queue behavior|Mixed read-data, raw `?ARLEN`?, runtime validation, and multi-beat output banks over generated mixed dynamic/static issue-order queues|current_boundary' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_ISSUE_ORDER_QUEUE_PUBLIC_SURFACE_SYNC.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md docs/book/src/11-extensions-and-embedding.md perl/FSM/Support/LanguageSurfaceSection.pm t/297-capability-manifest.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.511` synchronizes the public `.ppif`
downstream-contract, capability-manifest, and mdBook surfaces after generated
mixed dynamic/static same-ID issue-order queue behavior shipped through
`.503`, `.506`, and `.509`.

The downstream integration spec, public interface contract, embedding chapter,
and `language_surface.file_surfaces` `.ppif` `current_boundary` now advertise
generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID
issue-order queue behavior for write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST`.

`.511` does not change parser or generator behavior, PPIF samples, support
accounting, generated artifacts, schedule/check/semantic JSON, HDL/runtime
behavior, backend behavior, verification output, external converter behavior,
or VHDL behavior.
