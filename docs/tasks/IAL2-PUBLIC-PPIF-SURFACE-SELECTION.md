# IAL2-PUBLIC-PPIF-SURFACE-SELECTION: IAL2 Public PPIF Surface Selection

## Metadata

- Tree ID: `IAL2-PUBLIC-PPIF-SURFACE-SELECTION`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Select the generic public IAL2 file surface and first syntax boundary before
any parser or CLI suffix implementation starts.

## Non-Goals

- Do not implement a parser, CLI resolver, generated file writer, or HDL flow
  in this slice.
- Do not add `.ppif`, `.pif`, `.ppi`, `.axi`, or other suffix recognition to
  `bin/fsmgen`.
- Do not select a full AXI manager syntax.
- Do not change the mandatory `IAL2 -> IAL1 -> IAL0` lowering chain.

## Acceptance Criteria

- A decision record closes the generic IAL2 file-surface choice for the first
  public implementation slice.
- The decision records the first public `.ppif` source shape for one AXI
  Valid-Ready contract and its generated `.isf`/`.fsm`/report expectations.
- mdBook, README, IAL2 status docs, Knowledge Map, task tree, and MEMORY remain
  synchronized.
- No parser, CLI, or behavior changes are made.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PUBLIC-PPIF-SURFACE-SELECTION`
  Status: `done`
  Goal: `Select the generic IAL2 public file surface and first syntax boundary.`
  Children: `IAL2-PUBLIC-PPIF-SURFACE-SELECTION.1`

- ID: `IAL2-PUBLIC-PPIF-SURFACE-SELECTION.1`
  Status: `done`
  Goal: `Record .ppif as the first generic public IAL2 file surface and define the first Valid-Ready syntax boundary.`
  Acceptance: `Decision/docs/book/Knowledge Map state the .ppif surface and first syntax contract, with parser/CLI implementation deferred to a later exact owner.`
  Verification: `passed`
  Commit: `IAL2-PUBLIC-PPIF-SURFACE-SELECTION.1: select PPIF public surface`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PUBLIC-PPIF-SURFACE-SELECTION.1` | `done` | `.ppif` is selected and parser/CLI implementation remains deferred to a later exact owner. |

## Decisions

- `2026-06-12`: Run a decision slice before public parser/CLI implementation
  because decision `0014` still left `.pif`/`.ppi`/`.ppif` open.

## Open Questions

- Future protocol-profile aliases such as `.axi` remain deferred to later
  exact owners; they do not block selecting the generic `.ppif` surface.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PUBLIC-PPIF-SURFACE-SELECTION.1: select PPIF public surface` | `pending commit workflow` |

## Changelog

- `2026-06-12`: Created active decision task tree for the IAL2 public `.ppif`
  surface selection.
- `2026-06-12`: Selected `.ppif` as the first public generic IAL2 file surface,
  recorded the first Valid-Ready source shape, and synced live docs/Knowledge
  Map/MEMORY.
