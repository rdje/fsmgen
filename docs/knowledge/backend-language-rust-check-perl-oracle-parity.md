---
id: backend-language-rust-check-perl-oracle-parity
title: The Rust direct check smoke has a Perl-oracle parity test
answers:
  - "what did BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3 add?"
  - "how is the Rust direct FSM check smoke compared with the Perl oracle?"
  - "does the Rust parity smoke change the shipped Perl CLI?"
  - "which test covers Rust check JSON parity?"
  - "why can T1467 hang before the Rust parity program starts?"
date: 2026-09-06
status: current
tags: [architecture, portability, rust, parity, check-json, task-tree]
evidence: docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; rust/fsmgen-portable-api/Cargo.toml; rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs; rust/fsmgen-portable-api/src/lib.rs; rust/fsmgen-portable-api/README.md; t/1467-rust-portable-api-check-parity.t; t/corpus/direct_sreset_active_high.fsm; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md
reverify: rg -n 'fsmgen-portable-api-check-smoke|check_smoke_projection|t/1467-rust-portable-api-check-parity|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.3|direct_sreset_active_high|feature.direct_sreset_active_high|Perl-oracle parity|check_json|support_accounting' rust/fsmgen-portable-api/Cargo.toml rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs rust/fsmgen-portable-api/src/lib.rs rust/fsmgen-portable-api/README.md t/1467-rust-portable-api-check-parity.t t/corpus/direct_sreset_active_high.fsm docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/15-implementation-blueprint.md docs/knowledge/backend-language-rust-check-perl-oracle-parity.md
---

Frontier `.3.3` added the Rust experiment's first Perl-oracle parity smoke.

The crate's test-only `fsmgen-portable-api-check-smoke` runs `check` on
`t/corpus/direct_sreset_active_high.fsm`, emitting JSON-safe `check_json`.

T1467 compares decoded Perl (`./bin/fsmgen --check-json`) and Rust JSON: backend-portable schema
version, success, diagnostic count, input leaf, check-result summary, generated-output emission, and
support-accounting identity/classification fields.

No shipped Rust CLI; `bin/fsmgen`, Perl capability manifests, generated HDL, package installation
and runtime behavior remain unchanged.

2026-09-06: T1467's unbounded `IPC::Cmd::run` waited for a Rust child at `_dyld_start`; TERM exposed
failure. HIAL/VIAL `.19.2.3.1.2.2.4` owns the sample and pending bounded replay/policy.
