# BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH: Refresh The Live Entrypoint Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`
- Status: `proposed`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Refresh `docs/BIN_FSMGEN_IMPORT_TREE.md` from the live `bin/fsmgen` transitive
project import closure after later IAL2/AHB growth made the saved architecture
snapshot stale.

## Non-Goals

- Do not refactor runtime packages merely to change the measured snapshot.
- Do not combine feature work with the architecture-note refresh.

## Acceptance Criteria

- A live `Module::ScanDeps` scan is rerun from repository root.
- The note records the measured `227` project files / `226` `.pm` packages and
  the current `IAL2` family count of `19`, or the newly measured values if the
  import graph changes before activation.
- Stale selected line counts and reachability prose are refreshed from source.
- Focused docs, doctrine, memory, and diff gates pass and the leaf is committed
  through `COMMIT.md`.

## Task Tree

- ID: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`
  Status: `proposed`
  Goal: `Refresh the live bin/fsmgen import-tree architecture note.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1`
  Status: `proposed`
  Goal: `Re-measure and synchronize the import-tree note.`
  Acceptance: `Module::ScanDeps results, family counts, selected line counts, and prose agree with the live closure; no runtime behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Mandatory startup review measured `227` project files and
  `226` packages, including `19` under `FSM/IAL2`, while the maintained note
  still says `213` / `212` and `IAL2: 5`. The mismatch is pre-existing and is
  routed here rather than mixed into the same-volume policy adoption.

## Blockers

- Inactive until selected from a clean tree after the current adoption closes.
