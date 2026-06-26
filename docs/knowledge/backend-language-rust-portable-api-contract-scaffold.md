---
id: backend-language-rust-portable-api-contract-scaffold
title: The Rust portable API scaffold is additive and fail-closed
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1 add?"
  - "does the Rust fsmgen_portable_api crate change the Perl CLI?"
  - "what does the Rust portable API scaffold implement today?"
  - "what is the Rust unsupported operation diagnostic code?"
  - "what is the next Rust portability slice after the scaffold?"
date: 2026-06-26
status: current
tags: [architecture, portability, rust, api-contract, task-tree]
evidence: rust/Cargo.toml; rust/fsmgen-portable-api/Cargo.toml; rust/fsmgen-portable-api/README.md; rust/fsmgen-portable-api/src/lib.rs; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md
reverify: rg -n 'fsmgen_portable_api|E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE|E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3|rust/Cargo.toml|source_catalog|artifact_sink|direct_sreset_active_high|Rust contract crate' rust/Cargo.toml rust/fsmgen-portable-api/Cargo.toml rust/fsmgen-portable-api/README.md rust/fsmgen-portable-api/src/lib.rs docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-rust-portable-api-contract-scaffold.md docs/knowledge/backend-language-rust-direct-fsm-check-smoke.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1` added the same-repository
Rust workspace and `fsmgen_portable_api` crate under `rust/`.

The crate models the first portable API shell: request/result envelopes,
operation tokens, source identity, host profile, virtual artifacts,
diagnostics, support-accounting shape, implementation profile, and capability
profile.

The scaffold remains explicitly incomplete. Since `.3.2`, `capabilities()`
reports the `check` operation as partially implemented for one smoke fixture.
`execute(request)` succeeds only for `feature.direct_sreset_active_high`.
Other check inputs fail with `E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE`, and
non-check operations fail with `E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION`.

The crate is not wired into `bin/fsmgen`, Perl capability manifests, generated
HDL, package installation, or shipped runtime behavior. The active next slice
is `.3.3`, the Perl-oracle parity smoke for the direct `.fsm` check result.
