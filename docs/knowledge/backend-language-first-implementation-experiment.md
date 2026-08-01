---
id: backend-language-first-implementation-experiment
title: The first backend-language experiment is a same-repo Rust/Rust-Wasm API smoke
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8 select?"
  - "which implementation language is FSMGen trying first?"
  - "why was Rust selected before browser JavaScript Dart or Julia?"
  - "what is the first Rust portability slice?"
  - "what did the current Rust/Rust-Wasm smoke experiment complete?"
date: 2026-06-26
status: current
tags: [architecture, portability, rust, wasm, implementation-experiment]
evidence: docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md; docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md; docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md; rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs; t/1467-rust-portable-api-check-parity.t
reverify: >-
  rg -n 'BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3|Rust/Rust-Wasm portable API smoke|cargo 1.95.0|wasm-pack|source_catalog|artifact_sink|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3|fsmgen_portable_api|fsmgen-portable-api-check-smoke|t/1467-rust-portable-api-check-parity|direct_sreset_active_high' docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md
  rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs t/1467-rust-portable-api-check-parity.t docs/knowledge/backend-language-first-implementation-experiment.md docs/knowledge/backend-language-rust-portable-api-contract-scaffold.md docs/knowledge/backend-language-rust-direct-fsm-check-smoke.md docs/knowledge/backend-language-rust-check-perl-oracle-parity.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8` selected a same-repository
Rust/Rust-Wasm portable API smoke as the first backend-language implementation
experiment. The selected owner is
`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3`.

Rust was selected first because the roadmap names Rust as the H1 serious
implementation direction, it can grow toward Wasm, it fits the selected
request/result and source-catalog/artifact-sink contracts, and it can share the
same repository, mdBook, fixtures, and Perl-reference parity harness.

The first implementation slice, `.3.1`, scaffolded the Rust portable API
contract crate and tests under `rust/`, without wiring it into the current Perl
CLI or claiming shipped replacement behavior. `.3.2` added exactly one direct
`.fsm` check smoke for `feature.direct_sreset_active_high`. `.3.3` added the
first Perl-oracle parity smoke for that Rust check result and closed the
current Rust/Rust-Wasm smoke experiment frontier without changing the shipped
Perl CLI/runtime.
