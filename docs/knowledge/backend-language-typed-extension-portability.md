---
id: backend-language-typed-extension-portability
title: Current typed extensions are Perl-reference only for backend portability
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7 select?"
  - "are FSMGen typed extensions portable to non-Perl variants?"
  - "can the first non-Perl FSMGen implementation claim extension support?"
  - "what is Perl-specific about typed extension loading?"
  - "what comes after the typed extension portability audit?"
date: 2026-06-26
status: current
tags: [architecture, portability, extensions, plugins, perl]
evidence: docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md; docs/EXTENSION_MODEL.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/15-implementation-blueprint.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; perl/FSM/Support/ExtensionContract.pm; perl/FSM/Extension/Loader.pm; perl/FSM/Extension/Registry.pm; perl/FSM/Extension/Context.pm; t/391-typed-extension-programmatic-loading-boundary-audit.t; t/395-typed-extension-explicit-discovery-boundary-audit.t; t/401-typed-extension-module-name-shape-boundary-audit.t
reverify: rg -n 'BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT|BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7|typed extension|Perl reference|out of scope for the first non-Perl|Module::Name|source_catalog|artifact_sink|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1' docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md docs/EXTENSION_MODEL.md docs/book/src/11-extensions-and-embedding.md docs/book/src/15-implementation-blueprint.md docs/book/src/14-feature-backlog.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/knowledge/backend-language-typed-extension-portability.md docs/knowledge/backend-language-first-implementation-experiment.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7` selected the typed
extension portability boundary. The current extension system remains a bounded
Perl reference implementation surface, but it is not a backend-language-neutral
portable plugin API.

Perl-specific mechanics include blessed extension objects, `Module::Name`
loading through `@INC`/`require`, real `new()` constructor discovery,
`UNIVERSAL::can`, `FSM::Extension::*` object receiver shapes, live Perl
pipeline/result objects, and direct mutation of raw in-process result hashes.

Typed extension/plugin support is out of scope for the first non-Perl
implementation experiment unless a future exact task selects a portable
extension API first. A non-Perl variant that does not implement that future API
must advertise extension support as unsupported and fail closed on extension
loading requests. `.2.8` selected the same-repository Rust/Rust-Wasm portable
API smoke experiment. The next active backend-portability slice is `.3.1`, the
Rust contract-crate scaffold.
