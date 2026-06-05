---
id: generation-result-snapshot-embedding-child
title: Generation result snapshot is a direct embedding manifest child
answers:
  - "where is generation_result_snapshot advertised?"
  - "is generation_result_snapshot a direct embedding child?"
  - "what embedding API surface should tools use for HDLGenerator result summaries?"
  - "does generation_result_snapshot expose raw HDLGenerator objects?"
  - "how is the generation result snapshot contract exposed in the capability manifest?"
date: 2026-06-05
status: current
tags: [embedding, capability-manifest, hdl-generator, json]
evidence: perl/FSM/Support/EmbeddingContract.pm; perl/FSM/Support/EmbeddingSection.pm; perl/FSM/Support/SerializableGenerationResultSnapshot.pm; perl/FSM/Support/SerializablePlanReportContract.pm; t/321-embedding-contract.t; t/297-capability-manifest.t; t/358-capability-manifest-runtime-contract-audit.t; t/437-embedding-section-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/321-embedding-contract.t t/297-capability-manifest.t t/358-capability-manifest-runtime-contract-audit.t t/437-embedding-section-defensive-copy-boundary-audit.t t/632-serializable-generation-result-snapshot.t
---

`embedding.serializable_generation_result_snapshot` is the direct capability
manifest child for the JSON-safe `HDLGenerator` result summary contract. It is
owned by `FSM::Support::SerializableGenerationResultSnapshot` and records the
bounded public keys for generated module/source/HDL-size facts, semantic-layer
presence, and raw-shell presence/class metadata.

The direct child does not make raw `HDLGenerator` result hashes public JSON
payloads. The existing nested compatibility reference
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
remains available for plan/report discovery.
