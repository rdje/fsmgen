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
  - "which tasks own the large roadmap, task, book, changelog, development notes, and knowledge map migrations?"
date: 2026-07-31
status: current
tags: [documentation, doctrine, continuity, size, sharding, rollover, archive, harness-neutral]
evidence: LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/decisions/0007-memory-architecture-supersedes-blob-narration.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0025-project-document-interim-lifecycle.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md
reverify: scripts/check_readme_entrypoint.sh && wc -l -c ROADMAP_V2.md MEMORY.md docs/TASK_TREE.md DEVELOPMENT_NOTES.md KNOWLEDGE_MAP.md CHANGES.md docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is the project-owned doctrine. Its reusable
body is project-neutral, project-agnostic, and harness-neutral; FSMGen authority,
80/90/100 milestones, same-volume rule, measurements, paths, and migration
owners live only in its fenced adoption note, the local audit, and the future
data registry.

The central rule is “bounded live view over an addressable durable store.”
Current state overwrites, maintained user reference stays in navigable semantic
partitions, generated projections shard from small canonical sources, rolling
ledgers rotate and later archive, and exact old evidence uses an immutable
query-first terminal with digest/retrieval proof. Sharding alone is insufficient:
collections also need file-count and aggregate transitions.

Decision 0041 accepts the architecture. The measured revision and exact
family owners are in `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`. Clean
selection commit `139efbf90` completes
`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1` continuity activation; `.2` alone
is active to implement the common registry/checker before any family
migration. Selection and activation change no document topology, thresholds,
frozen content, or product behavior.
