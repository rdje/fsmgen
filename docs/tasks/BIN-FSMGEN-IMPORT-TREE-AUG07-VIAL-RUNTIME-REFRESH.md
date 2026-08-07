# BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH: Refresh The Public VIAL Runtime Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-08-07`
- Last updated: `2026-08-07`
- Owner: repo-local workflow

## Goal

Synchronize the import-tree note, fact, and HIAL/VIAL book snapshots with the
live closure after the public portable-SystemVerilog runtime shipped.

## Non-Goals

- Do not change runtime behavior or widen support beyond the qualified
  `sv_portable_verilator` profile.
- Do not activate provider-blocked, proposed, or director-gated work.

## Acceptance Criteria

- A live `Module::ScanDeps` scan is rerun from repository root.
- Note/fact counts and an exact package-set comparison match the live closure.
- Public VIAL runtime and private/review-only UVM/VHDL boundaries are accurate.
- The backlog and canonical architecture chapters agree with the live frontier.
- Documentation, Knowledge Map, memory, book, diff, and doctrine gates pass
  with no off-volume project data or repository-local build residue.
- The shipped-behavior maintained-reference aggregate records this leaf's
  exact measured book delta; no health target or ceiling increases.
- Runtime behavior remains unchanged and the completed leaf is committed
  through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH`
  Status: `done`
  Goal: `Synchronize the public-VIAL-runtime bin/fsmgen architecture note, fact, and book snapshots.`
  Children: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1`
  Status: `done`
  Goal: `Remeasure and synchronize the six-package VIAL runtime import-map drift.`
  Acceptance: `Live closure counts and package membership, runtime-spine prose, canonical fact, and mdBook snapshots agree with source while behavior and support claims remain unchanged.`
  Verification: `Activated by clean commit c56d39ab8. Module::ScanDeps reports 254 project files / 253 packages / Support 76 / IAL2 19 / VIAL 17 / HIAL 3. A set comparison proves 253 unique package links exactly match the closure; every selected line count matches wc. The note now records public run through SVPortableVerilator, Runner, TraceValidator, and ResultProducer while keeping native-UVM/VHDL backends private. The fact and both HIAL/VIAL book snapshots are current. bin/fsmgen syntax passes; VIAL t1555/t1556 pass Files=2/Tests=10; clean book/path/containment audits pass Files=4/Tests=314. All 52 mdBook chapters test; the 86-file build succeeds in .artifacts/mdbook and is removed exactly. Knowledge Map passes at 1,105 facts / 5,689 questions / 5,855 occurrences / 118 shards. Live-document containment passes all 22 surfaces: the import note compaction keeps focused documents below transition allowance, the book authority records exactly +6 lines/+514 bytes, and no ceiling rises. Task integrity, Memory, relative paths, diff hygiene, staged doctrines, and residue checks pass. Broader probes expose two pre-existing oracle drifts: t350 omits status values introduced by 7725789a4/0074b369e, while t1256/t1332 still read the pre-dc1c64afb monolithic backlog. Untouched sources prove both unrelated; the next clean task owns repair.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-AUG07-VIAL-RUNTIME-REFRESH.1: refresh public VIAL runtime map`

## Decisions

- `2026-08-07`: Startup remeasurement found `254` project files / `253`
  packages / `19` IAL2 / `17` VIAL / `3` HIAL owners. The maintained note and
  fact still record `248` / `247` / `19` / `13` / `3`, omit six reachable
  VIAL runtime/support owners, and still deny a public backend/runtime path.
- `2026-08-07`: Keep the repair documentation-only. The canonical Chapter 16d
  body states the current qualified boundaries, while its opening retains one
  stale `.15.4` status; Chapter 14e needs a synchronized current summary and
  completed `.10.4`/`.11` progress record. Both fixes remain in this leaf.
- `2026-08-07`: Chapter changes replace the single-use `.15.4` shipped-
  behavior aggregate authority with this leaf's exact predecessor/delta;
  containment targets and ceilings remain unchanged.
- `2026-08-07`: A broader audit found two unrelated post-evolution test-oracle
  drifts. `t/350` lacks the current UVM/VHDL contract statuses introduced by
  `7725789a4` and `0074b369e`; `t/1256` and `t/1332` still inspect only the
  monolithic Chapter 14 after partition commit `dc1c64afb`. The next clean
  slice must create their exact repair owner before changing tests.

## Acceptance Checklist (enforced) — `.1` public VIAL runtime map refresh

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'247 project packages' --oneline
  -- docs/BIN_FSMGEN_IMPORT_TREE.md docs/knowledge/bin-fsmgen-import-tree-current-baseline.md`
  identifies the retained pre-runtime baseline, while the live
  `Module::ScanDeps` scan reports `254` project files / `253` packages and the
  exact package-set comparison names six reachable VIAL runtime/support owners
  absent from both maintained snapshots.
- [x] **ADDRESSED (verified)** — the repeated live scan reports `254` files /
  `253` packages / Support `76` / IAL2 `19` / VIAL `17` / HIAL `3`; all `253`
  package links match the closure with zero missing or extra entries, selected
  source line counts match `wc`, and the note, fact, generated map, Memory, and
  HIAL/VIAL book summaries now describe the same public-runtime boundary.
- [x] **NO REGRESSION** — the focused VIAL and clean documentation suites
  report `All tests successful` at `Files=2, Tests=10` and `Files=4,
  Tests=314`; all 52 mdBook chapters test, the repository-local 86-file build
  succeeds and is removed exactly, Knowledge Map and containment pass, no
  health target or ceiling rises, and runtime sources remain unchanged.

## Blockers

- None.
