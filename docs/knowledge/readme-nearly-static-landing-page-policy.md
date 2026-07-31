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
date: 2026-07-31
status: current
tags: [readme, documentation, doctrine, continuity, onboarding, routing, pressure-control]
evidence: README.md; README_POLICY.md; docs/decisions/0024-readme-is-a-nearly-static-landing-page.md; docs/decisions/0038-readme-policy-is-harness-neutral-and-locally-authoritative.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md; doctrine/readme_entrypoint/routed_destinations.tsv; scripts/check_readme_entrypoint.sh; scripts/check_doctrines.sh; docs/tasks/README-POLICY-ANVIL-ADOPTION-FEEDBACK.md; docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md
reverify: wc -l -c README.md && scripts/check_readme_entrypoint.sh && rg -n 'README_LINE_CAP|README_BYTE_CAP|ROUTE_REGISTRY|frozen_roadmap_status|frozen_achievement_status' scripts/check_readme_entrypoint.sh doctrine/readme_entrypoint/routed_destinations.tsv
---

`README.md` is a concise, nearly static GitHub landing page. It changes only
when the project objective, first-use path, top-level architecture, or
canonical navigation changes. Dynamic behavior, status, rationale, facts,
inventories, and history stay in their canonical maintained layers.

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
overflow. FSMGen declares those controls in
`doctrine/readme_entrypoint/routed_destinations.tsv`; the unconditional README
doctrine validates them even when neither README nor the destination changed.
Measured legacy ceilings are stop-growth debt boundaries, not recommended
defaults. Clean guard commit `45fc6631e` activates the next selection of a
project-wide live-document size-containment doctrine; no sharding, rollover,
archive, threshold, or live-document content change has yet occurred.
