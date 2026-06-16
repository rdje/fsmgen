# BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER: Backend-Language Portability Contract

## Metadata

- Tree ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`
- Status: `active`
- Roadmap lane: `Backend portability / public contracts`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Ensure FSMGen has explicit public contracts, infrastructure, test strategy,
documentation, and task ownership for future implementations in languages or
runtimes other than the current Perl 5 reference implementation, including
Rust/Rust-Wasm, browser-capable JavaScript, Dart/web, Julia, and future
in-memory or embedded hosts.

## Non-Goals

- Do not start a second implementation in this tree before the contract audit
  identifies an exact executable slice.
- Do not change IAL0, IAL1, IAL2, parser, lowerer, HDL, MCP, or runtime
  behavior under the tree-creation leaf.
- Do not select Rust, Julia, Dart, JavaScript, or any other language as the
  mandatory next implementation target in this tree-creation leaf.
- Do not weaken the current Perl 5 implementation's role as the reference
  implementation/oracle while portability contracts are audited.

## Acceptance Criteria

- Backend-language portability work has a dedicated task-tree owner.
- The task tree records the current accepted backend-neutral doctrine from
  `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`.
- The next frontier is an audit leaf that covers public source syntax,
  generated review artifacts, diagnostics, support accounting, semantic JSON,
  MCP-facing introspection, in-memory API expectations, fixture parity,
  host-abstraction boundaries, and mdBook/user-facing contract transparency.
- README, roadmap, mdBook, Memory, Knowledge Map, and the task-tree index point
  at the new owner where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`
  Status: `active`
  Goal: `Own the backend-language portability contract and infrastructure audit frontier.`
  Children: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1`
  Status: `done`
  Goal: `Create the backend-language portability contract task tree.`
  Acceptance: `Add the active task-tree owner, register it in docs/TASK_TREE.md, keep the public README/roadmap/mdBook surfaces aligned with decision 0018, update Memory and Knowledge Map, run doc/continuity checks, and commit the docs-only slice without code behavior changes.`
  Verification: `passed`
  Commit: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1: create portability task tree`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2`
  Status: `pending`
  Goal: `Audit backend-language-neutral contract and infrastructure readiness.`
  Acceptance: `Read decision 0018, README, roadmap, mdBook, semantic-introspection/MCP tree, current source/report/diagnostic/support-accounting/semantic JSON/MCP surfaces, public examples, regression corpus, CLI behavior, in-process Perl APIs, generated artifacts, and relevant task trees; identify every Perl/POSIX/process/filesystem/module-loading assumption that is public contract versus current implementation detail; define the portable in-memory execution contract needed by Rust/Rust-Wasm, browser-capable JavaScript, Dart/web, Julia, and future hosts; map parity requirements for source syntax, diagnostics, support accounting, semantic JSON, MCP resources/tools, examples, review artifacts, and HDL outputs; record exact future implementation leaves, validation gates, docs/book impact, compatibility risks, and rollback boundaries before any code or public-contract changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2` | `pending` | `.1` created the owner tree; the next step is an audit before any portability infrastructure or implementation-language work changes code or public contracts. |

## Decisions

- `2026-06-16`: Created this tree to make backend-language portability
  contract work task-tree owned instead of conversation-only backlog.
- `2026-06-16`: Decision `0018` remains the governing architecture rule:
  IAL0, IAL1, IAL2, public file formats, reports, diagnostics, examples, and
  mdBook explanations are backend-language-neutral contracts; Perl 5 is the
  current reference implementation, not the portable IAL definition.

## Open Questions

- Which implementation language should be attempted first after the audit:
  Rust/Rust-Wasm, browser JavaScript, Dart/web, Julia, or another host? This
  does not block `.2`; the audit must define selection criteria and parity
  gates before choosing an implementation slice.
- Which public in-memory API shape should be canonical for non-CLI hosts? This
  does not block `.2`; the audit must separate semantic contract from current
  Perl CLI/module entrypoints.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1` | `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README numbering check | `passed`; created active backend-language portability task-tree owner and registered the pending audit frontier |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1: create portability task tree` | Created the owner tree and advanced the frontier to `.2`, the backend-language-neutral contract/infrastructure audit. |

## Changelog

- `2026-06-16`: Created the backend-language portability contract frontier and
  made `.2` the pending audit owner for future Rust/Rust-Wasm, browser
  JavaScript, Dart/web, Julia, and other non-Perl/in-memory host work.
