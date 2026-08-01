---
id: readme-nearly-static-landing-page-policy
title: README policy closes landing-page and routed-destination pressure
answers:
  - "what is the README maintenance policy?"
  - "when should README.md change?"
  - "how is README growth prevented?"
  - "where is the project-neutral reusable README policy?"
  - "what are the README line and byte caps?"
  - "may a harness bootstrap file authorize the README policy?"
  - "is the README policy template an upstream?"
  - "does the README guard run when README.md did not change?"
  - "can README overflow be moved into an unbounded status file?"
  - "how are README destinations pressure controlled?"
  - "where is the README routed destination registry?"
  - "are frozen legacy status files valid README destinations?"
  - "is README.md the GitHub project landing page?"
date: 2026-08-01
status: current
tags: [readme, documentation, doctrine, continuity, onboarding, routing, pressure-control]
evidence: >-
  README.md; README_POLICY.md; LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0024-readme-is-a-nearly-static-landing-page.md; docs/decisions/0038-readme-policy-is-harness-neutral-and-locally-authoritative.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0048-achievement-history-is-task-trees-book-and-git.md; docs/decisions/0049-roadmap-status-is-roadmap-task-trees-memory-and-git.md; doctrine/readme_entrypoint/routed_destinations.jsonl; doctrine/live_document_size/surfaces.jsonl; scripts/check_readme_entrypoint.sh; scripts/check_live_document_size.sh; scripts/check_doctrines.sh; docs/tasks/README-POLICY-ANVIL-ADOPTION-FEEDBACK.md;
  docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: wc -l -c README.md && scripts/check_readme_entrypoint.sh && scripts/check_live_document_size.sh && rg -n 'ROUTE_REGISTRY|SURFACE_REGISTRY|exact_history' scripts/check_readme_entrypoint.sh doctrine/readme_entrypoint/routed_destinations.jsonl doctrine/live_document_size/surfaces.jsonl
---

`README.md` is a concise, nearly static GitHub landing page and therefore a
first-class user interface, not merely a bootstrap pointer. It changes only
when the project objective, first-use path, top-level architecture, or
canonical navigation changes. Those four functions remain directly visible;
dynamic detail, status, rationale, exhaustive inventories, and history stay in
their canonical maintained layers.

FSMGen enforces a maximum of 275 lines and 12,288 bytes, derived from its
reviewed 246-line / 9,952-byte survivor, plus the existing per-leaf chronology
guard through `scripts/check_readme_entrypoint.sh`. The doctrine driver runs
that tree invariant on every commit and CI build, independent of changed paths.

`README_POLICY.md` is the authoritative project-owned copy. Its reusable body
is project- and harness-neutral; local authority is FSMGen maintainers plus the
dated adopting decisions, never a harness bootstrap. The originating template
is not an upstream and is not synchronized automatically. Apparent duplicate
README content is proved against its canonical home before deletion or
relocation, and richer canonical content is retained through one link.

Decision `0040` adds routing pressure closure. Moving detail out of README is
not success until every named destination terminates in a classified control:
live files have line/byte ceilings, partitioned collections have per-part and
aggregate ceilings, generated indexes retain freshness gates, append ledgers
must shard before their ceiling, query/archive terminals remain query-first,
and frozen legacy files are pinned by content identity and cannot receive new
overflow. FSMGen maps those routes in
`doctrine/readme_entrypoint/routed_destinations.jsonl`; common lifecycle and
pressure declarations live once in `doctrine/live_document_size/surfaces.jsonl`.
The unconditional doctrines validate them even when neither README nor a
destination changed.
Measured legacy ceilings are stop-growth debt boundaries, not recommended
defaults. Decision `0041` now selects the broader project-neutral,
project-agnostic, harness-neutral live-document doctrine and assigns each
high-water/structural migration owner. No sharding, rollover, archive,
threshold, or live-document content change occurs in the selection itself.
Implementation leaf `.2` adds the common JSONL registry and neutral checker;
the direct README landing contract remains unchanged.

Decisions `0048` and `0049` retire the former frozen achievement and roadmap
status paths after independent value audits. They are no longer README
destinations; their exact objects remain available through the bounded
`exact_history` contract, while README routes current questions directly to
the task, book, roadmap, Memory, and Git authorities.
