---
id: downstream-consumer-contract-lockstep
title: Downstream codebase, handoff, contracts, manifest, support accounting, and book stay lockstep
answers:
  - "must downstream handoff docs stay in sync with the codebase?"
  - "must the mdBook stay in sync with downstream contracts?"
  - "what surfaces must change together for downstream-visible behavior?"
  - "is the downstream integration handoff SPECFORGE-specific?"
  - "where is the downstream consumer lockstep doctrine recorded?"
  - "must public source.resolved_path be repository relative?"
date: 2026-08-11
status: current
tags: [downstream, contracts, mdbook, handoff, integration, manifest, support-accounting]
evidence: README.md; ROADMAP_V2.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/ReportSourceContract.pm; docs/book/src/11-extensions-and-embedding.md; docs/book/src/13i-downstream-integration.md; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md
reverify: rg -n 'downstream consumer|downstream-visible|lockstep|language_surface\\.file_surfaces|source\\.resolved_path|GITHUB-PUSH-OUTCOME-ASSURANCE\\.6\\.2\\.1' README.md ROADMAP_V2.md docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md docs/ISF_PUBLIC_INTERFACE_CONTRACT.md perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/ReportSourceContract.pm docs/book/src/11-extensions-and-embedding.md docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md docs/TASK_TREE.md
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

The 2026-08-11 pre-push audit classified all 19 commits after the pushed SHA.
CLI help and strict schedule JSON were byte-identical; capability, check, and
semantic JSON were identical after normalizing only documented revision/path
provenance. Nineteen stale handoff commands were corrected from off-volume
`/tmp` destinations to repository-local `.artifacts` paths.

Public check/semantic JSON deliberately emits absolute `source.resolved_path`;
code, docs, and tests agree, and the CI repair did not change it. That old
consumer-visible contract conflicts with a literal reading of the newer
repository-relative path doctrine. On 2026-08-11 the director authorized the
repaired CI push and separated this independent compatibility decision into
proposed tree `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT`; its `.1` leaf must select
a compatible relative-path migration or narrow explicit exemption before any
field-semantic implementation change.
