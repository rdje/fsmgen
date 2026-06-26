---
id: backend-language-rust-check-perl-oracle-parity
title: The Rust direct check smoke has a Perl-oracle parity test
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3 add?"
  - "how is the Rust direct FSM check smoke compared with the Perl oracle?"
  - "does the Rust parity smoke change the shipped Perl CLI?"
  - "which test covers Rust check JSON parity?"
date: 2026-06-26
status: current
tags: [architecture, portability, rust, parity, check-json, task-tree]
evidence: rust/fsmgen-portable-api/Cargo.toml; rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs; rust/fsmgen-portable-api/src/lib.rs; rust/fsmgen-portable-api/README.md; t/1467-rust-portable-api-check-parity.t; t/corpus/direct_sreset_active_high.fsm; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md
reverify: rg -n 'fsmgen-portable-api-check-smoke|check_smoke_projection|t/1467-rust-portable-api-check-parity|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3|direct_sreset_active_high|feature.direct_sreset_active_high|Perl-oracle parity|check_json|support_accounting' rust/fsmgen-portable-api/Cargo.toml rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs rust/fsmgen-portable-api/src/lib.rs rust/fsmgen-portable-api/README.md t/1467-rust-portable-api-check-parity.t t/corpus/direct_sreset_active_high.fsm docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-rust-check-perl-oracle-parity.md
---

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3` added the first
Perl-oracle parity smoke for the Rust portable API experiment.

The Rust crate now registers the test-only
`fsmgen-portable-api-check-smoke` binary. Given the
`t/corpus/direct_sreset_active_high.fsm` fixture, it executes the Rust
`check` operation and emits the crate's JSON-safe `check_json` projection.

`t/1467-rust-portable-api-check-parity.t` runs both the Perl oracle
`./bin/fsmgen --check-json` and the Rust projection, decodes both JSON outputs,
and compares the normalized backend-portable fields: schema version, success,
diagnostic count, source input leaf, check-result summary, generated-output
emission, and support-accounting identity/classification fields.

This is not a shipped Rust CLI and does not wire Rust into `bin/fsmgen`, Perl
capability manifests, generated HDL, package installation, or runtime behavior.
