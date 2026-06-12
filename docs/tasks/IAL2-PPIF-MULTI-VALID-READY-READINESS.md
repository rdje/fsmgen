# IAL2-PPIF-MULTI-VALID-READY-READINESS: Map Multi-Channel PPIF Readiness

## Metadata

- Tree ID: `IAL2-PPIF-MULTI-VALID-READY-READINESS`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Record the code, report, CLI, and documentation prerequisites that must be
settled before widening `.ppif` from one Valid-Ready channel object to multiple
Valid-Ready channel objects in one IAL2 file.

## Non-Goals

- Do not change parser, generator, CLI, report, HDL, or test behavior.
- Do not relax the existing duplicate `valid-ready-channel` diagnostic.
- Do not implement AXI five-channel manager behavior, transaction IDs,
  outstanding-window scheduling, response matching, bursts, or dependency
  rules.
- Do not select `.pif`, `.ppi`, `.axi`, or any protocol-profile alias.

## Acceptance Criteria

- The readiness note identifies the current single-object assumptions in the
  `.ppif` adapter, Valid-Ready generator, CLI artifact path, and `.isf` parser.
- The readiness note states the contract decisions required before a future
  multi-channel implementation leaf can safely change behavior.
- The mdBook feature backlog points at the readiness result without implying
  multi-object `.ppif` support has shipped.
- A Knowledge Map fact card captures the durable "why not just a parser
  change" answer for future sessions.
- Focused docs, Knowledge Map, memory, path, and diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-MULTI-VALID-READY-READINESS`
  Status: `done`
  Goal: `Map the prerequisites for future multi-channel .ppif support.`
  Children: `IAL2-PPIF-MULTI-VALID-READY-READINESS.1`

- ID: `IAL2-PPIF-MULTI-VALID-READY-READINESS.1`
  Status: `done`
  Goal: `Document the multi-channel .ppif blockers and future contract choices.`
  Acceptance: `Task tree, readiness note, mdBook backlog, Knowledge Map fact, generated map, and MEMORY pointer all agree that multi-object .ppif remains unshipped and needs an aggregate result/source/artifact contract before parser relaxation.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-MULTI-VALID-READY-READINESS.1: map multi-channel PPIF blockers`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-MULTI-VALID-READY-READINESS.1` | `done` | Readiness note now records why multi-channel `.ppif` needs an aggregate result/report/source-artifact contract before parser behavior changes. |

## Decisions

- `2026-06-12`: Treat this as a readiness/contract-mapping slice. The future
  behavior leaf must choose an aggregate PPIF result/report/source-artifact
  contract before any parser acceptance changes.

## Open Questions

- None for this readiness slice. Future implementation owners still have to
  choose between a multi-artifact PPIF result, an ISF wrapper/top actor, or
  continued one-object-per-file composition.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-MULTI-VALID-READY-READINESS.1` | `mdbook build docs/book`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-MULTI-VALID-READY-READINESS.1` | `IAL2-PPIF-MULTI-VALID-READY-READINESS.1: map multi-channel PPIF blockers` | `completed` |

## Changelog

- `2026-06-12`: Created task tree and selected the readiness/contract-mapping
  leaf for future multi-channel `.ppif` support.
- `2026-06-12`: Completed readiness mapping, mdBook sync, Knowledge Map fact,
  generated map update, and validation for the current multi-object `.ppif`
  fail-closed boundary.
