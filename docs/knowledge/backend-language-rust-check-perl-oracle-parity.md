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
evidence: t/lib/FSM/Test/RustParityRuntime.pm; t/1810-rust-parity-runtime.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; rust/fsmgen-portable-api/Cargo.toml; rust/fsmgen-portable-api/src/bin/check_smoke_projection.rs; rust/fsmgen-portable-api/src/lib.rs; rust/fsmgen-portable-api/README.md; t/1467-rust-portable-api-check-parity.t; t/corpus/direct_sreset_active_high.fsm; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/book/src/14-feature-backlog.md; docs/book/src/15-implementation-blueprint.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/1467-rust-portable-api-check-parity.t t/1669-task-acceptance-fixture-runtime.t t/1810-rust-parity-runtime.t
---

Frontier `.3.3` added T1467's Perl-oracle comparison for
`t/corpus/direct_sreset_active_high.fsm`: schema, success, diagnostic count,
input leaf, result summary, emission, and support-accounting fields.
The test-only Rust projection emits `check_json`; no Rust CLI is shipped.

HIAL/VIAL `.19.2.3.1.2.2.4` owns the failed `_dyld_start` sample and bounded
controls. Its `.4.2` adapter separates locked offline build, Perl oracle, and
direct Rust execution, with sealed tools, admitted fresh local artifacts,
finite stage bounds, split streams, first-failure truth, and group cleanup.
T1810 and T1669 watch hostile paths and failures. The book owns usage;
the task owns exact policy and evidence. No OS cause or full-CI pass is inferred.
