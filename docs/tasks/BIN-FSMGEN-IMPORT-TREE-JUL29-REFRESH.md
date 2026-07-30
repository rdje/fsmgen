# BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH: Refresh The Live Entrypoint Import Map

## Metadata

- Tree ID: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`
- Status: `active`
- Roadmap lane: `bootstrap architecture maintenance`
- Created: `2026-07-29`
- Last updated: `2026-07-30`
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
  Status: `active`
  Goal: `Refresh the live bin/fsmgen import-tree architecture note.`
  Children: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1`

- ID: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1`
  Status: `active`
  Goal: `Re-measure and synchronize the import-tree note.`
  Acceptance: `Module::ScanDeps results, family counts, selected line counts, and prose agree with the live closure; no runtime behavior changes.`
  Verification: `Activated only after clean parent selector commit 23a987e06. This continuity leaf changes no import-tree note/fact, runtime package, parser, generator, public source, support accounting, artifact, API, HDL/runtime, backend, protocol, HIAL/VIAL, portability, scale, or decision-0020 behavior; the stale 213-file / 212-package / 5-IAL2 note and canonical fact remain untouched. Focused verification passed 329 tests across 5 files (t/1256, t/1303, t/1305, t/1332, and t/1414); Knowledge Map generation/check passed at 1,064 facts / 5,477 question keys; mdBook built 72 files / 16,545,847 bytes and book/build was removed; .artifacts/tmp/tests is empty; MEMORY.md is 47 lines and README.md is 2,353 lines; diff hygiene and all six doctrine checks pass. The closeout RAM sample was 18,200,133,632 / 25,769,803,776 bytes (16.950 / 24.000 GiB, 70.63%) by the canonical macOS accounting formula, with kernel pressure level 1 and memory_pressure reporting 75% free; the guard's host reading is excluded from capacity truth. No background job remains.`
  Commit: `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH.1: activate import map refresh`

## Decisions

- `2026-07-29`: Mandatory startup review measured `227` project files and
  `226` packages, including `19` under `FSM/IAL2`, while the maintained note
  still says `213` / `212` and `IAL2: 5`. The mismatch is pre-existing and is
  routed here rather than mixed into the same-volume policy adoption.

## Blockers

- Active only after clean selector commit `23a987e06`; remeasure and repair the
  architecture note without changing runtime behavior.
