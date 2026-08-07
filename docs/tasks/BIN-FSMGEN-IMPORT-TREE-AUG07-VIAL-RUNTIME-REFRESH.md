# BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH: Refresh The Public VIAL Runtime Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH`
- Status: `active`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-08-07`
- Last updated: `2026-08-07`
- Owner: repo-local workflow

## Goal

Synchronize the import-tree note, fact, and older HIAL/VIAL backlog snapshot
with the live closure after the public portable-SystemVerilog runtime shipped.

## Non-Goals

- Do not change runtime behavior or widen support beyond the qualified
  `sv_portable_verilator` profile.
- Do not activate provider-blocked, proposed, or director-gated work.

## Acceptance Criteria

- A live `Module::ScanDeps` scan is rerun from repository root.
- Note/fact counts and an exact package-set comparison match the live closure.
- Public VIAL runtime and private/review-only UVM/VHDL boundaries are accurate.
- The older book snapshot agrees with the canonical architecture chapter.
- Documentation, Knowledge Map, memory, book, diff, and doctrine gates pass
  with no off-volume project data or repository-local build residue.
- Runtime behavior remains unchanged and the completed leaf is committed
  through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH`
  Status: `active`
  Goal: `Synchronize the public-VIAL-runtime bin/fsmgen architecture note, fact, and book snapshot.`
  Children: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1`
  Status: `active`
  Goal: `Remeasure and synchronize the six-package VIAL runtime import-map drift.`
  Acceptance: `Live closure counts and package membership, runtime-spine prose, canonical fact, and mdBook snapshot agree with source while behavior and support claims remain unchanged.`
  Verification: `Activation creates the exact documentation-only owner and synchronizes task/index/Memory continuity while leaving the stale note, fact, book snapshot, and runtime unchanged. Task-tree integrity passes at five active trees / 919 nodes. Knowledge Map passes at 1,105 facts / 5,687 questions. Relative-path audit passes Files=1/Tests=2; Memory is 39 lines; live-document containment passes all 22 surfaces with no ceiling increase after compacting the active index within its existing transition allowance; diff hygiene passes.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1: activate VIAL runtime import-map refresh`

## Decisions

- `2026-08-07`: Startup remeasurement found `254` project files / `253`
  packages / `19` IAL2 / `17` VIAL / `3` HIAL owners. The maintained note and
  fact still record `248` / `247` / `19` / `13` / `3`, omit six reachable
  VIAL runtime/support owners, and still deny a public backend/runtime path.
- `2026-08-07`: Keep the repair documentation-only. The canonical Chapter 16d
  already states the current qualified boundaries; Chapter 14e needs only a
  synchronized current summary and completed `.10.4`/`.11` progress record.

## Blockers

- None.
