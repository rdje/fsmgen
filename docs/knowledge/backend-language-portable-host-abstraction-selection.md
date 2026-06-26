---
id: backend-language-portable-host-abstraction-selection
title: Portable host abstraction uses a source catalog plus artifact sink
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4 select?"
  - "what is FSMGen's portable source artifact host abstraction?"
  - "does the portable host abstraction require a filesystem?"
  - "how does the filesystem CLI map to the portable host abstraction?"
  - "what comes after the host abstraction selection?"
date: 2026-06-26
status: current
tags: [architecture, portability, host-abstraction, artifacts, source-identity]
evidence: docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md; docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md; docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md; perl/FSM/SourcePathResolver.pm; perl/FSM/Support/ReportSourceContract.pm
reverify: rg -n 'BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION|BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION|BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION|BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT|BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7|source_catalog|artifact_sink|filesystem CLI remains an adapter|FSMLIB|--path|--outdir|pure in-memory|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1' docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md docs/BACKEND_LANGUAGE_FIRST_IMPLEMENTATION_EXPERIMENT_SELECTION.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-portable-host-abstraction-selection.md docs/knowledge/backend-language-portable-parity-harness-selection.md docs/knowledge/backend-language-mdbook-blueprint-selection.md docs/knowledge/backend-language-typed-extension-portability.md docs/knowledge/backend-language-first-implementation-experiment.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4` selected a two-part
portable host abstraction: `source_catalog` resolves source identities to source
text plus bounded metadata, and `artifact_sink` accepts virtual artifacts from
lowering, HDL generation, and verification-output operations.

The pure in-memory API must not require a POSIX filesystem, current working
directory, environment variables, temporary files, process spawning, or Perl
module loading. The current filesystem CLI remains an adapter: `--path`,
`FSMLIB`, current-directory fallback, `--outdir`, `--output`, and
verification-output directories map onto the same source-catalog/artifact-sink
model.

`.2.5` has since selected the Perl-reference parity harness and normalization
rules, `.2.6` selected the mdBook implementation-blueprint chapter structure,
and `.2.7` selected current typed extensions as Perl-reference only for
backend portability. `.2.8` selected the same-repository Rust/Rust-Wasm
portable API smoke experiment. The `.3.1` through `.3.3` slices then
scaffolded the Rust contract crate, added one direct `.fsm` check smoke, and
proved that result against the Perl oracle.
