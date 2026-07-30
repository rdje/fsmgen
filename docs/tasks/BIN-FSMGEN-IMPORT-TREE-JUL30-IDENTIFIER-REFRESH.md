# BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH: Refresh The Identifier-Era Entrypoint Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Refresh `docs/BIN_FSMGEN_IMPORT_TREE.md` and its canonical fact from the live
`bin/fsmgen` transitive project import closure after the portable identifier
implementation added one reachable Support owner.

## Non-Goals

- Do not refactor or otherwise change runtime packages.
- Do not combine the separate Chapter 16c AHB busy-count residue repair with
  this import-map synchronization.
- Do not activate HIAL/VIAL, HIR, scale, MCP-write, other protocol/backend,
  simulator, transaction-architecture, lifecycle-review, or director-gated
  work.

## Acceptance Criteria

- A live `Module::ScanDeps` scan is rerun from repository root.
- The note and canonical fact record `229` project files / `228` `.pm`
  packages / `19` IAL2 owners, or the newly measured values if the graph moves
  again before implementation.
- The note records `Support 71`, links the reachable portable identifier policy
  honestly, and remains exact against the live closure.
- Focused documentation, Knowledge Map, memory, diff, and doctrine gates pass.
- Runtime behavior, public support accounting, generated artifacts, and both
  frozen status files remain unchanged.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH`
  Status: `done`
  Goal: `Synchronize the identifier-era bin/fsmgen import-tree architecture note and fact.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1`
  Status: `done`
  Goal: `Remeasure and synchronize the one-package import-map drift.`
  Acceptance: `Module::ScanDeps results, family counts, live-package representation, and canonical fact agree with the live closure; no runtime or unrelated documentation behavior changes.`
  Verification: `Activated only after clean parent selector commit 28d3e777a through clean continuity commit ccf01c686. Module::ScanDeps reports 229 project files / 228 packages / 19 IAL2 owners and Support 71; the added package is exactly FSM::Support::HDLInstanceIdentifierPolicy. A set comparison proves the note's 228 unique package links match all 228 live packages exactly with no missing or extra package link. Refreshed the three closure counts, Support count, portable policy reachability/inventory, and every stale selected line count changed since the July 29 baseline; an automated comparison reports no remaining measured-line mismatch. bin/fsmgen syntax passes. Five focused documentation audits pass with Files=5, Tests=329; Knowledge Map passes at 1,073 facts / 5,530 question keys; memory architecture passes with MEMORY.md at 47 lines; the mdBook HTML build passes and its exact repository-local render is removed; diff hygiene passes. The note/fact now agree with live source; runtime code, public accounting, generated artifacts, product behavior, the separate AHB residue, and both frozen status files remain unchanged.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUL30-IDENTIFIER-REFRESH.1: refresh identifier-era import map`

## Decisions

- `2026-07-30`: Parent selector `.839` measured `229` project files / `228`
  packages / `19` IAL2 owners and traced the added reachable
  `FSM::Support::HDLInstanceIdentifierPolicy` package exactly to clean commit
  `299db4cae`.
- `2026-07-30`: Keep the Chapter 16c counts-beyond-four contradiction as a
  separate next documentation owner so this leaf remains a canonical
  architecture-map correction only.
- `2026-07-30`: Completed the documentation-only refresh at `229` / `228` /
  `19`, including `Support 71`, the portable identifier policy, and current
  selected line counts.

## Blockers

- None.
