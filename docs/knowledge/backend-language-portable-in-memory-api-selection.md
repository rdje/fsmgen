---
id: backend-language-portable-in-memory-api-selection
title: Portable in-memory API candidate uses request/result envelopes and virtual artifacts
answers:
  - "what candidate did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3 draft?"
  - "what is FSMGen's candidate portable in-memory API shape?"
  - "does the candidate portable API require filesystem paths?"
  - "how should generated artifacts be returned by an in-memory FSMGen candidate?"
  - "what blocks the portable in-memory API selection?"
date: 2026-06-26
status: blocked
tags: [architecture, portability, in-memory-api, host-abstraction, artifacts]
evidence: docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/Support/CheckDiagnostics.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/SerializableGenerationResultSnapshot.pm; perl/FSM/Support/HDLGeneratorResultContract.pm; perl/FSM/Support/VerificationOutputsContract.pm
reverify: rg -n 'BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3|blocked|request/result|capabilities\\(request\\?\\)|execute\\(request\\)|virtual artifact|filesystem CLI remains an adapter|JSON-safe result|t/301-check-json-supported-corpus' docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/backend-language-portable-in-memory-api-selection.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3` drafted a candidate
portable in-memory request/result API family, not a Perl module API name. The
conceptual entrypoints are `capabilities(request?)` and `execute(request)`,
with operation tokens for `check`, `lower`, `schedule`, `semantic`,
`generate_hdl`, and `verification_output`.

The candidate API is source-text and source-identity based. It must not
require POSIX filesystem paths, process spawning, Perl module loading, Perl
object receivers, raw private AST/IR objects, or raw HDLGenerator result
hashes in the pure in-memory path.

Generated review, HDL, and verification artifacts should return as JSON-safe
virtual artifact entries with stable relative identities, kind, role,
language, content, source layer, and generated-from provenance. The filesystem
CLI remains an adapter over that model.

The selection is blocked pending verification: the focused `t/301` corpus
proof remained on
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`
for about 44 minutes at roughly 11 GB RSS and was terminated before the full
gate completed. `.2.4` must not start until `.2.3` completes.
