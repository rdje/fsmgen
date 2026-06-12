# IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION: Select PPIF Bundle HDL Entry Contract

## Metadata

- Tree ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Select the first safe HDL entry contract for multi-channel `.ppif`
Valid-Ready bundles before any wrapper/top HDL implementation begins.

## Non-Goals

- Do not implement bundle wrapper/top HDL in this selection slice.
- Do not change CLI behavior, generated artifacts, parser behavior, or HDL
  emission.
- Do not implement AXI manager transactions, IDs, bursts, responses,
  outstanding-window scheduling, ordering, or cross-channel dependencies.
- Do not add `.pif`, `.ppi`, `.axi`, or other protocol-profile aliases.

## Acceptance Criteria

- A durable selection note records the future bundle HDL entry shape and why
  it avoids "first channel wins" behavior.
- The mdBook feature backlog points at the selected future HDL contract.
- A fact card and generated Knowledge Map entry make the selection retrievable.
- Task-tree, README/MEMORY as needed, Knowledge Map, memory, path, book, and
  diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION`
  Status: `done`
  Goal: `Select the future PPIF bundle HDL entry contract.`
  Children: `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1`

- ID: `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1`
  Status: `done`
  Goal: `Record the safe future wrapper/top HDL entry contract for PPIF bundles.`
  Acceptance: `Docs, mdBook, fact card, Knowledge Map, task tree, and memory agree that future bundle HDL must use an aggregate wrapper/top entry rather than one generated channel root.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1: select PPIF bundle HDL entry`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1` | `done` | Selected the future aggregate wrapper/top HDL entry contract. |

## Decisions

- `2026-06-12`: This is a selection-only slice. Implementation waits for a
  later exact owner after the wrapper/top contract is recorded.

## Open Questions

- None for the selection slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1` | `IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.1: select PPIF bundle HDL entry` | `pending commit` |

## Changelog

- `2026-06-12`: Created task tree and selected the PPIF bundle HDL entry
  contract slice as the next PNT activity.
- `2026-06-12`: Selected aggregate wrapper/top as the future PPIF bundle HDL
  entry contract and rejected first-channel root selection.
