---
id: downstream-consumer-contract-lockstep
title: Downstream codebase, handoff, contracts, manifest, support accounting, and book stay lockstep
answers:
  - "must downstream handoff docs stay in sync with the codebase?"
  - "must the mdBook stay in sync with downstream contracts?"
  - "what surfaces must change together for downstream-visible behavior?"
  - "is the downstream integration handoff SPECFORGE-specific?"
  - "where is the downstream consumer lockstep doctrine recorded?"
date: 2026-06-16
status: current
tags: [downstream, contracts, mdbook, handoff, integration, manifest, support-accounting]
evidence: README.md; ROADMAP_V2.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; perl/FSM/Support/LanguageSurfaceSection.pm; docs/book/src/11-extensions-and-embedding.md; docs/book/src/13i-downstream-integration.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md
reverify: rg -n 'downstream consumer|downstream-visible|lockstep|language_surface\\.file_surfaces|deeper concrete same-ID|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.148' README.md ROADMAP_V2.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md perl/FSM/Support/LanguageSurfaceSection.pm docs/book/src/11-extensions-and-embedding.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md
---

Any downstream-visible change must keep the codebase, downstream
handoff/integration docs, public contracts, capability-manifest metadata,
support-accounting catalog entries, tests, explicit deferrals, and mdBook in
lockstep. These surfaces convey the same facts from different viewpoints for
any downstream consumer; drift is a project bug.

The doctrine is generic to all downstream consumers. SPECFORGE is one consumer,
but the integration handoff, public contracts, capability manifest, support
accounting, and mdBook are not SPECFORGE-specific.

For `.isf` and `.ppif`, the lockstep surfaces include
`docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`,
`docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, the mdBook downstream integration and
embedding chapters, `language_surface.file_surfaces` in the capability
manifest, support-accounting catalog entries, tests, README, roadmap, Memory,
Knowledge Map, and the owning task tree.
