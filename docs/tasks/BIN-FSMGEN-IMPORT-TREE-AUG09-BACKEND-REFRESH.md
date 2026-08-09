# BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH: Refresh The Post-Backend-Fix Entrypoint Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH`
- Status: `done`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-08-09`
- Last updated: `2026-08-09`
- Owner: repo-local workflow

## Goal

Restore `docs/BIN_FSMGEN_IMPORT_TREE.md` as an exact, navigable view of the
live `bin/fsmgen` transitive project import closure after the August 8 bounded
backend-work fixes.

## Non-Goals

- Do not change behavior, tests, generated artifacts, support accounting,
  containment ceilings, or unrelated roadmap activation.

## Acceptance Criteria

- Activate this owner from a clean repository before the map changes.
- Rerun the canonical `Module::ScanDeps` closure and exact package-link set
  comparison from repository root.
- Refresh stale counts and repair malformed links while retaining containment.
- Keep the fact, index, Memory, and unchanged mdBook boundary aligned; focused
  documentation and doctrine gates pass without build residue.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH`
  Status: `done`
  Goal: `Synchronize and restore the post-backend-fix bin/fsmgen import-tree architecture map.`
  Children: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.1, BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.2`

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.1`
  Status: `done`
  Goal: `Activate the exact documentation-only import-map repair owner.`
  Acceptance: `Task/index/Memory continuity records the bounded repair before the maintained map changes; focused continuity gates pass.`
  Verification: `Activated from clean commit 70ba62f35. Task-tree integrity passes at five active trees / 922 nodes; Memory passes at 41 lines; Knowledge Map passes at 1,105 facts / 5,706 questions / 5,872 occurrences / 118 shards; the relative-path audit passes Files=1/Tests=2; live-document containment and diff hygiene pass without a ceiling increase. The maintained map, canonical fact, runtime, tests, generated artifacts, and public behavior remain unchanged in this activation slice.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.1: activate backend import-map refresh`

- ID: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.2`
  Status: `done`
  Goal: `Remeasure and restore the maintained import map and canonical fact.`
  Acceptance: `Closure counts and package membership remain exact, every selected measured line count matches source, no malformed Markdown link remains, and documentation/doctrine gates pass without behavior changes.`
  Verification: `Activated by clean commit 2411e012f. Module::ScanDeps reports 254 project files / 253 packages / Support 76 / IAL2 19 / VIAL 17 / HIAL 3; the map has exactly 253 unique live-package links with zero missing or extra owners. All 71 selected line counts match source. The August 1 reflow root cause is repaired from 49 split destinations, four split labels, and two split label/destination delimiters to zero; all 13 parent-relative link targets are repository-root-relative, and maximum physical line length remains 473 bytes. The canonical fact and generated shard are current; bin/fsmgen syntax, task integrity, Memory, Knowledge Map, relative paths, diff hygiene, and containment pass. All 52 mdBook chapters test and the 87-file repository-local build succeeds; its exact output is removed. Runtime, tests, source inputs, generated artifacts, public support claims, and mdBook content remain unchanged.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-AUG09-BACKEND-REFRESH.2: refresh backend import map`

## Decisions

- `2026-08-09`: The canonical scan still reports `254` project files / `253`
  packages / Support `76` / IAL2 `19` / VIAL `17` / HIAL `3`; topology and
  public support claims are unchanged.
- `2026-08-09`: Post-baseline backend commits changed nine reachable owners;
  only the selected `RegressionCorpus.pm` count is stale, `6820 -> 6884`.
- `2026-08-09`: Exact Markdown-link parsing finds 49 destinations, four
  labels, and two label/destination delimiters split across physical lines by
  `ea1b76dd5`; eight live packages have no remaining valid canonical link.
  Restore atomic Markdown tokens within bounded lines.
- `2026-08-09`: Completed the documentation-only refresh without topology or
  behavior change; the restored map is exact and navigable under containment.

## Blockers

- None.
