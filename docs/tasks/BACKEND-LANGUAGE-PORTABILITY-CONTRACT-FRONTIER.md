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
in-memory or embedded hosts. The ultimate portability target is identical
in-memory behavior on any suitable platform/environment, with every language
variant kept on par for functionality, features, diagnostics, semantic
introspection, examples, fixtures, and tests. The Perl implementation is the
de facto reference/oracle for parity until another explicit decision changes
that role. The mdBook must eventually contain enough contract detail for a
competent implementer to build a conforming FSMGen variant in language X
without reading Perl internals as the source of truth. Every future variant or
implementation must satisfy the same FSMGen public contracts.

## Non-Goals

- Do not start a second implementation in this tree before the contract audit
  identifies an exact executable slice.
- Do not change IAL0, IAL1, IAL2, parser, lowerer, HDL, MCP, or runtime
  behavior under tree-creation or doctrine-capture leaves.
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
- The portability doctrine records that every implementation-language variant
  must be systematically portable, in-memory capable where the host allows it,
  and parity-checked against the Perl reference/oracle across functionality,
  features, diagnostics, semantic introspection, examples, fixtures, and tests.
- The portability doctrine records that every future variant or implementation
  must satisfy FSMGen's public contracts rather than defining a parallel or
  reduced contract.
- The portability doctrine records that the mdBook must grow into the
  language-independent implementation blueprint for conforming variants, not
  only a user guide for the current Perl implementation.
- README, roadmap, mdBook, Memory, Knowledge Map, and the task-tree index point
  at the new owner where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER`
  Status: `active`
  Goal: `Own the backend-language portability contract and infrastructure audit frontier.`
  Children: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1`
  Status: `done`
  Goal: `Create the backend-language portability contract task tree.`
  Acceptance: `Add the active task-tree owner, register it in docs/TASK_TREE.md, keep the public README/roadmap/mdBook surfaces aligned with decision 0018, update Memory and Knowledge Map, run doc/continuity checks, and commit the docs-only slice without code behavior changes.`
  Verification: `passed`
  Commit: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1: create portability task tree`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2`
  Status: `active`
  Goal: `Audit backend-language-neutral contract and infrastructure readiness.`
  Children: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2, BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`
  Acceptance: `Read decision 0018, README, roadmap, mdBook, semantic-introspection/MCP tree, current source/report/diagnostic/support-accounting/semantic JSON/MCP surfaces, public examples, regression corpus, CLI behavior, in-process Perl APIs, generated artifacts, and relevant task trees; identify every Perl/POSIX/process/filesystem/module-loading assumption that is public contract versus current implementation detail; define the portable in-memory execution contract needed by Rust/Rust-Wasm, browser-capable JavaScript, Dart/web, Julia, and future hosts; map parity requirements for source syntax, diagnostics, support accounting, semantic JSON, MCP resources/tools, examples, review artifacts, HDL outputs, and test suites; define how the Perl reference/oracle is used to prove that every variant satisfies the same FSMGen public contracts; define what the mdBook must contain so an implementation in language X can be built from public contracts rather than Perl internals; record exact future implementation leaves, validation gates, docs/book impact, compatibility risks, and rollback boundaries before any code or public-contract changes.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1`
  Status: `done`
  Goal: `Capture the cross-implementation parity doctrine.`
  Acceptance: `Record the user-stated doctrine that FSMGen's ultimate goal is identical in-memory behavior on any platform/environment through any conforming backend language; every future variant or implementation must satisfy FSMGen's public contracts and be on par for functionality, features, diagnostics, semantic introspection, examples, fixtures, and tests; the Perl implementation is the de facto reference/oracle for parity; and the mdBook must contain enough language-independent contract detail to guide a conforming implementation in language X. Sync README, roadmap, mdBook, task tree, Memory, and Knowledge Map without code behavior changes.`
  Verification: `passed`
  Commit: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1: capture variant parity doctrine`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2`
  Status: `active`
  Goal: `Perform the backend-language-neutral contract and infrastructure readiness audit.`
  Children: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`
  Acceptance: `Execute the parent audit after the cross-implementation parity doctrine is captured: read the public contract, task-tree, decision, code, test, support-accounting, semantic JSON, MCP, examples, regression corpus, CLI, and in-process API surfaces; separate public contract from Perl implementation detail; define the portable in-memory execution/API contract; define parity harness requirements against the Perl reference/oracle that prove every variant satisfies FSMGen's public contracts; define mdBook blueprint gaps for language-X implementations; select exact future leaves and validation gates before any code or public-contract changes.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1`
  Status: `done`
  Goal: `Synchronize the downstream-consumer handoff, integration specs, public contracts, capability-manifest language surface, and mdBook with the current codebase.`
  Acceptance: `Audit the live codebase surfaces that downstream consumers use now: capability manifest language_surface.file_surfaces, support-accounting PPIF catalog entries, .ppif schedule/check/semantic JSON behavior for the current AXI manager queue-head samples, docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md, docs/ISF_PUBLIC_INTERFACE_CONTRACT.md, relevant downstream feedback/status docs where they reference the public surface, docs/book/src/11-extensions-and-embedding.md, docs/book/src/13i-downstream-integration.md, docs/book/src/14-feature-backlog.md, README, roadmap, Memory, and Knowledge Map; update stale downstream-visible contract wording so codebase/handoff/integration/contracts/book are lockstep for any downstream consumer, including but not specific to SPECFORGE; preserve behavior except for contract metadata/prose; keep frozen legacy blobs untouched; run focused manifest/PPIF/docs/book/continuity checks; commit and push per user request.`
  Verification: `passed`
  Commit: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1: sync downstream contract surfaces`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2` | `active` | `.2.2.1` synchronized the downstream-consumer handoff, integration specs, public contracts, manifest language surface, support accounting, and mdBook; resume the broader backend-language-neutral contract/infrastructure readiness audit. |

## Decisions

- `2026-06-16`: Created this tree to make backend-language portability
  contract work task-tree owned instead of conversation-only backlog.
- `2026-06-16`: Decision `0018` remains the governing architecture rule:
  IAL0, IAL1, IAL2, public file formats, reports, diagnostics, examples, and
  mdBook explanations are backend-language-neutral contracts; Perl 5 is the
  current reference implementation, not the portable IAL definition.
- `2026-06-16`: Captured the clarified parity doctrine: FSMGen's ultimate
  portability goal is identical in-memory behavior on any suitable platform
  through any conforming backend language, every variant must stay on par for
  functionality/features/tests and public semantic surfaces, every future
  variant must satisfy FSMGen public contracts, Perl remains the de facto
  parity oracle, and the mdBook must become sufficient contract material for
  implementing a conforming language-X variant.
- `2026-06-16`: Added `.2.2.1` as the urgent downstream-consumer sync leaf for
  handoff, integration specs, public contracts, capability-manifest language
  surface, and mdBook lockstep with current codebase behavior.
- `2026-06-16`: Completed `.2.2.1` as a generic downstream-consumer sync, not a
  SPECFORGE-specific handoff: codebase manifest metadata, support-accounting
  catalog docs, integration handoff, public contracts, README, roadmap, book,
  Knowledge Map, and task-tree state now carry the same current `.ppif`/IAL2
  bounded-public boundary and deferrals.

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
| `2026-06-16` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1` | `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README numbering check | `passed`; captured the cross-implementation parity doctrine and advanced the audit frontier to `.2.2` |
| `2026-06-16` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1` | `env -u PERL5LIB perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `env -u PERL5LIB prove -Iperl t/297-capability-manifest.t t/317-language-surface-contract.t t/483-language-surface-section-defensive-copy-boundary-audit.t`; `env -u PERL5LIB prove -Iperl t/1436-ial2-ppif-parser-cli.t t/248-regression-corpus-accounting.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check`; README numbering check | `passed`; synchronized downstream handoff/integration/contracts/manifest/support-accounting/book surfaces with the current codebase boundary for all downstream consumers |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.1: create portability task tree` | Created the owner tree and advanced the frontier to `.2`, the backend-language-neutral contract/infrastructure audit. |
| `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.1: capture variant parity doctrine` | Captured identical in-memory behavior, variant parity, mandatory FSMGen contract satisfaction, Perl oracle, and mdBook language-X blueprint doctrine; advanced the audit frontier to `.2.2`. |
| `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1` | `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.2.1: sync downstream contract surfaces` | Synchronized the downstream-consumer handoff, integration specs, public contracts, manifest language surface, support-accounting catalog docs, README, roadmap, book, and Knowledge Map; resumed `.2.2` as the broader backend portability audit frontier. |

## Changelog

- `2026-06-16`: Created the backend-language portability contract frontier and
  made `.2` the pending audit owner for future Rust/Rust-Wasm, browser
  JavaScript, Dart/web, Julia, and other non-Perl/in-memory host work.
- `2026-06-16`: Captured the cross-implementation parity doctrine and made
  `.2.2` the pending audit owner.
- `2026-06-16`: Added `.2.2.1` as the immediate downstream-consumer sync owner
  before changing downstream-visible contract metadata or documentation.
- `2026-06-16`: Completed `.2.2.1`; the current `.ppif`/IAL2 bounded-public
  boundary and deferrals are aligned across codebase, handoff, integration
  specs, public contracts, capability manifest, support-accounting docs,
  README, roadmap, mdBook, and Knowledge Map for all downstream consumers.
