---
id: live-document-size-containment
title: Live documents use bounded views over durable stores
answers:
  - "how are live-document sizes contained project-wide?"
  - "what happens when a live document reaches its size warning?"
  - "where does old changelog or task-tree history go?"
  - "does sharding alone contain documentation growth?"
  - "how is archived document content proved retrievable?"
  - "is the live-document doctrine project neutral?"
  - "is the live-document doctrine harness neutral?"
  - "where are FSMGen live-document measurements recorded?"
  - "what format does the live-document registry use?"
  - "why does the live-document registry use JSONL instead of TSV?"
  - "does the project-wide checker cover README.md itself?"
  - "which tasks own the large roadmap, task, book, changelog, development notes, and knowledge map migrations?"
date: 2026-07-31
status: current
tags: [documentation, doctrine, continuity, size, sharding, rollover, archive, harness-neutral]
evidence: LIVE_DOCUMENT_SIZE_CONTAINMENT.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/readme_entrypoint/routed_destinations.jsonl; scripts/check_live_document_size.sh; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/decisions/0007-memory-architecture-supersedes-blob-narration.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0025-project-document-interim-lifecycle.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md
reverify: scripts/check_live_document_size.sh && prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t
---

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is the project-owned doctrine. Its reusable
body is project-neutral, project-agnostic, and harness-neutral; FSMGen authority,
80/90/100 milestones, same-volume rule, measurements, paths, and migration
owners live only in its fenced adoption note, the local audit, and JSONL data
registries.

The central rule is “bounded live view over an addressable durable store.”
Current state overwrites, maintained user reference stays in navigable semantic
partitions, generated projections shard from small canonical sources, rolling
ledgers rotate and later archive, and exact old evidence uses an immutable
query-first terminal with digest/retrieval proof. Sharding alone is insufficient:
collections also need file-count and aggregate transitions.

Decision 0041 accepts the architecture. The measured revision and exact family
owners are in `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`. Leaf `.2` uses
JSONL because one named object per line preserves streaming/diff behavior while
replacing a brittle 22-column positional prototype with typed nested budgets,
arrays, `null`, and strict unknown-key failure. The neutral checker inventories
all tracked Markdown, including the GitHub README landing page itself, and
enforces locality, lifecycle, pressure, non-worsening transition baselines,
routes, projections, frozen identities, and archive descriptors before any
family migration. Decision `0042` and `.6` now define optional bounded,
exact-provenance task segments and compact terminals without migrating an
existing tree; `.7` owns the first IAL2/outlier/index migration.
Clean bounded-history commit `78adb81ae` activates `.7` alone; the activation
does not yet move a task node or cross-tree index row.

Implementation `.7` seals all 844 terminal IAL2 children from exact revision
`44b5f159789ba1c31b487c6b047097bb27a9770d`, retaining an 85-line live root and
one exact-capped content-addressed segment. It also replaces 540 unique terminal
index rows with a 523-byte bounded JSONL version-object manifest while keeping
three active and eleven proposed rows live. The index falls from 1,078 to 558
lines; both registered task surfaces are now `normal`, and no completed task
file or README landing content is removed.
