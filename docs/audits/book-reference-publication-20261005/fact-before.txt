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
  - "where is current packed record port behavior documented for downstream consumers?"
date: 2026-10-02
status: current
tags: [downstream, contracts, mdbook, handoff, integration, manifest, support-accounting]
evidence: docs/audits/record-output-predecessors-20261002/manifest.json; docs/isf-spec/11-downstream-actor-transactions.md; docs/isf-spec/12-downstream-rules-artifacts-reports.md; docs/isf-spec/22-public-interface-reports-evolution.md; README.md; ROADMAP_V2.md; docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md; docs/ISF_PUBLIC_INTERFACE_CONTRACT.md; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/ReportSourceContract.pm; docs/book/src/11-extensions-and-embedding.md; docs/book/src/13i-downstream-integration.md; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md
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

The published downstream chapter once included only the handoff landing page.
Its part links resolved outside the book, so a book reader did not receive the
contract. `DOWNSTREAM-BOOK-CONTRACT-INCLUDE` includes the canonical parts in
that chapter. The landing page remains the GitHub index and keeps its
repository-relative part links.

The 2026-10-02 targeted actor-port review repairs stale blanket record refusals
in the canonical source/report parts and public contract, alongside outdated
future classification for the shipped AXI/APB/AHB suffixes. Downstream section
8 now gives a complete lowering-clean input/storage/output record example and
exact copy, field/sample, physical writer, domain and target-profile boundaries.
The report parts describe current ordered typed leaf metadata. Input binary
SystemVerilog observations and remaining output generated/field/runtime gates
are explicit. The complete request remains open.

Actual example native/API/newline, strict carriers, literal metadata and current
capability entries provide re-derivation. Typed shared-corruption/membership
controls and exact canonical/rendered source comparisons provide falsification.
Complete source/report/manifest/render receipts, historical stale-source witness,
sealed verifier and task/book/feedback/Git retain durability. This targeted
lockstep repair does not claim a whole-document historical audit or new HDL
execution. Generic downstream contracts remain canonical for every consumer.

Maintained record-output corpus promotion also updates these canonical parts in
the same slice. The current direct representative, literal layout, bounded
phases/nonclaims and complete discovery/cohort applicability are documented;
residual old output deferrals are repaired against current source/public facts.
See [corpus closure](isf-record-output-corpus-closure.md). Generated output
handoff, field writes and runtime remain separately owned.
