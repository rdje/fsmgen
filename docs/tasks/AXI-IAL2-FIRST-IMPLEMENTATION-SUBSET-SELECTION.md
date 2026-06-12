# AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION: AXI IAL2 First Implementation Subset Selection

## Metadata

- Tree ID: `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Select the first safe AXI-derived IAL2 implementation subset and define the
minimum lowering, report, documentation, and validation contract required
before any code changes.

## Non-Goals

- Do not implement IAL2 syntax, parser, lowering, `.isf`, `.fsm`, HDL, tests,
  or generated artifacts in this slice.
- Do not claim a full AXI manager is selected for first implementation.
- Do not weaken the future AXI manager API direction or Easy-mode concurrency
  requirement.
- Do not bypass the mandatory `IAL2 -> IAL1 -> IAL0` lowering chain.

## Acceptance Criteria

- The task tree owns the implementation-selection work before the selection
  note is written.
- A repo-local note selects the first bounded AXI-derived IAL2 subset and
  records why larger AXI manager behavior remains deferred.
- The note defines the minimum source surface, generated IAL1 artifact shape,
  generated IAL0 artifact shape, report contract, focused validation, mdBook
  requirements, and explicit residue for the future implementation leaf.
- The mdBook backlog, README, task tree, Knowledge Map, IAL2 evaluation, AXI
  manager brainstorm, rule matrix, and memory remain synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION`
  Status: `done`
  Goal: `Select the first safe AXI-derived IAL2 implementation subset.`
  Children: `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.1`

- ID: `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.1`
  Status: `done`
  Goal: `Write the first implementation subset selection note.`
  Acceptance: `Use the existing AXI evidence, API brainstorm, and rule matrix to choose one bounded first implementation subset with explicit lowering/report/test/book requirements and no code behavior selected by this slice.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `bash scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.1: select first AXI IAL2 subset`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.1` | `done` | Selected the bounded first shipped subset as an AXI Valid-Ready channel contract/monitor with explicit future lowering, report, docs, validation, and residue requirements. |

## Decisions

- `2026-06-12`: Select the first implementation subset in documentation
  before any code or test changes.

## Open Questions

- The first implementation subset is selected as the Valid-Ready channel
  contract/monitor. Syntax, parser/lowerer code, generated fixture names, and
  HDL assertions require a later implementation owner before code changes.

## Blockers

- None for the doc-only selection.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `bash scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.1: select first AXI IAL2 subset` | Selected the Valid-Ready channel contract/monitor as the first AXI-derived IAL2 implementation subset; no code implementation shipped. |

## Changelog

- `2026-06-12`: Created active task tree for first AXI-derived IAL2
  implementation subset selection.
- `2026-06-12`: Closed `.1` by selecting the Valid-Ready channel
  contract/monitor subset and recording the pre-code contract.
