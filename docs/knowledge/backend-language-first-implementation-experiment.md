---
id: backend-language-first-implementation-experiment
title: The first backend-language experiment is a same-repo Rust/Rust-Wasm API smoke
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8 select?"
  - "which implementation language is FSMGen trying first?"
  - "why was Rust selected before browser JavaScript Dart or Julia?"
  - "what is the first Rust portability slice?"
  - "what comes after the first implementation-language selection?"
date: 2026-06-26
status: current
tags: [architecture, portability, rust, wasm, implementation-experiment]
evidence: docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md; docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md; docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md
reverify: rg -n 'BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3|Rust/Rust-Wasm portable API smoke|cargo 1.95.0|wasm-pack|source_catalog|artifact_sink|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2|fsmgen_portable_api' docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-first-implementation-experiment.md docs/knowledge/backend-language-rust-portable-api-contract-scaffold.md
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
CLI or claiming shipped replacement behavior. The active next slice is `.3.2`,
the first direct `.fsm` check-operation smoke in Rust.
