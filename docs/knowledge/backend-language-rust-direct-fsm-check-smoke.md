---
id: backend-language-rust-direct-fsm-check-smoke
title: The first Rust check smoke supports one direct FSM fixture
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2 add?"
  - "which FSM fixture does the Rust portable API check support?"
  - "does the Rust portable API support general FSM check yet?"
  - "what diagnostic does unsupported Rust check source return?"
  - "has the Rust direct FSM check smoke been compared with the Perl oracle?"
date: 2026-06-26
status: current
tags: [architecture, portability, rust, fsm, check-json, task-tree]
evidence: rust/fsmgen-portable-api/src/lib.rs; rust/fsmgen-portable-api/Cargo.toml; rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs; rust/fsmgen-portable-api/README.md; t/corpus/direct_sreset_active_high.fsm; t/1467-rust-portable-api-check-parity.t; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md
reverify: rg -n 'direct_sreset_active_high|feature.direct_sreset_active_high|E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE|E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3|fsmgen-portable-api-check-smoke|t/1467-rust-portable-api-check-parity|check_json|supported_smoke' rust/fsmgen-portable-api/src/lib.rs rust/fsmgen-portable-api/Cargo.toml rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs rust/fsmgen-portable-api/README.md t/corpus/direct_sreset_active_high.fsm t/1467-rust-portable-api-check-parity.t docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-rust-direct-fsm-check-smoke.md docs/knowledge/backend-language-rust-check-perl-oracle-parity.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.2` added the first direct
Rust `.fsm` check smoke to `fsmgen_portable_api`.

The only supported source is the normalized `feature.direct_sreset_active_high`
fixture from `t/corpus/direct_sreset_active_high.fsm`. It returns a JSON-safe
check result with `module_name: direct_sreset_active_high`, one state, one
signal, no generated HDL emission, and matched `supported_smoke` support
accounting.

The Rust crate does not support general `.fsm` check yet. Other check sources
fail closed with `E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE`; non-check
operations still fail with `E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION`.

The `.3.3` slice added the first Perl-oracle parity smoke for this result:
`fsmgen-portable-api-check-smoke` emits the Rust check projection and
`t/1467-rust-portable-api-check-parity.t` compares normalized check-JSON fields
against the Perl oracle. The shipped Perl CLI/runtime is unchanged.
