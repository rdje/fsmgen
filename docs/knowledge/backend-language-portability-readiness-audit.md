---
id: backend-language-portability-readiness-audit
title: Backend-language portability needs contract selectors before implementation
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2 decide?"
  - "is FSMGen ready to start a Rust implementation now?"
  - "what is the next backend portability task?"
  - "what portability work remains before non-Perl implementation code?"
  - "what is public contract versus Perl implementation detail?"
date: 2026-06-26
status: current
tags: [architecture, portability, in-memory-api, rust, wasm, javascript, dart]
evidence: >-
  docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md; docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md; perl/FSM/Support/CapabilityManifest.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/HDLGeneratorFacadeContract.pm; perl/FSM/Support/SemanticIntrospectionSection.pm; perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm; bin/fsmgen;
  bin/fsmgen-mcp; t/297-capability-manifest.t; t/301-check-json-supported-corpus.t; t/303-normalized-semantic-json-supported-corpus.t
reverify: >-
  rg -n 'BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT|BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION|BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION|BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION|BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.3|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7|portable in-memory API|host abstraction|parity harness|implementation blueprint|request/result|virtual artifacts|Perl implementation detail|Perl reference/oracle|source/report/manifest|non-Perl implementation|Rust/Rust-Wasm|browser
  JavaScript|Dart/web' docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/decisions/0018-ial-contracts-are-backend-language-neutral.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-portability-readiness-audit.md docs/knowledge/backend-language-portable-in-memory-api-selection.md docs/knowledge/backend-language-portable-host-abstraction-selection.md
  docs/knowledge/backend-language-portable-parity-harness-selection.md docs/knowledge/backend-language-mdbook-blueprint-selection.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` completed the
backend-language portability readiness audit. The audit finds that FSMGen has
strong public source/report/manifest/support-accounting/semantic/MCP/corpus
surfaces for parity planning, but it is not ready to start non-Perl
implementation code until exact contracts are selected for the portable
in-memory API, source/artifact host abstraction, Perl-oracle parity harness,
mdBook language-X blueprint, and extension/plugin portability boundary. Leaves
`.2.3`, `.2.4`, `.2.5`, and `.2.6` have now selected the request/result API,
the source-catalog plus artifact-sink host abstraction, the Perl-reference
parity harness, and the mdBook implementation-blueprint chapter structure.

Public contract means observable source syntax, generated review artifacts,
machine-readable reports, diagnostics, support accounting, semantic
introspection, generated outputs, regression corpus behavior, and mdBook
semantics. Perl package names, blessed object mechanics, filesystem/tempfile
usage, environment-variable search, process spawning, Perl module loading, raw
private AST/IR objects, and process-global debug behavior are current
reference implementation details.

The next active portability task is
`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7`, auditing typed
extension and plugin portability before any Rust/Rust-Wasm, browser JavaScript,
Dart/web, Julia, or other non-Perl implementation code.
