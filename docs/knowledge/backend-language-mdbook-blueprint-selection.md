---
id: backend-language-mdbook-blueprint-selection
title: The mdBook implementation blueprint uses a dedicated Chapter 15 structure
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6 select?"
  - "where is the language-X implementation blueprint in the mdBook?"
  - "what sections must the FSMGen implementation blueprint contain?"
  - "does the implementation blueprint start a non-Perl implementation?"
  - "what comes after the mdBook blueprint selection?"
date: 2026-06-26
status: current
tags: [architecture, portability, mdbook, implementation-blueprint, documentation]
evidence: docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md; docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md; docs/book/src/15-implementation-blueprint.md; docs/book/src/SUMMARY.md; docs/book/src/14-feature-backlog.md; docs/book/src/90-reference-map.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md
reverify: rg -n 'BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION|BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT|BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION|15-implementation-blueprint|Implementation Blueprint|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6|source_catalog|artifact_sink|capabilities\\(request\\?\\)|execute\\(request\\)|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1' docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md docs/book/src/SUMMARY.md docs/book/src/15-implementation-blueprint.md docs/book/src/14-feature-backlog.md docs/book/src/90-reference-map.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/knowledge/backend-language-mdbook-blueprint-selection.md docs/knowledge/backend-language-typed-extension-portability.md docs/knowledge/backend-language-first-implementation-experiment.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6` selected a dedicated
mdBook implementation-blueprint structure in
`docs/book/src/15-implementation-blueprint.md`. The chapter is a public
blueprint entry point and status surface; it does not start or select a
non-Perl implementation.

The selected section families are source-layer contracts, lowering order,
portable request/result API, host source/artifact model, report and manifest
contracts, artifact semantics, diagnostics and support accounting, backend
output boundaries, semantic introspection/MCP, parity harness, extension/plugin
portability status, and an implementation checklist.

`.2.7` has since selected current typed extensions as Perl-reference only for
backend portability. `.2.8` selected the same-repository Rust/Rust-Wasm
portable API smoke experiment. The next active backend-portability slice is
`.3.1`, the Rust contract-crate scaffold.
