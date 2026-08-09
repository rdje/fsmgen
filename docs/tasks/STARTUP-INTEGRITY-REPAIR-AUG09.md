# STARTUP-INTEGRITY-REPAIR-AUG09: Restore Startup Audit Integrity

## Metadata

- Tree ID: `STARTUP-INTEGRITY-REPAIR-AUG09`
- Status: `active`
- Roadmap lane: `bootstrap integrity maintenance`
- Created: `2026-08-09`
- Last updated: `2026-08-09`
- Owner: repo-local workflow

## Goal

Restore the test, mdBook, and entrypoint-architecture truths found stale by
the August 9 startup audit without changing behavior or roadmap claims.

## Non-Goals

- Do not change generation, strict behavior, supported surfaces, verification
  semantics, roadmap activation, or generated review artifacts.

## Acceptance Criteria

- Commit this owner from the clean baseline before maintained content changes.
- The HIAL direct-VHDL determinism lock names the current intentional output
  produced after the exact identifier/equality normalization change, and the
  focused HIAL/VIAL tests pass.
- The cookbook teaches canonical list-form composition wiring and identifies
  slash links only as default-mode compatibility input; its runnable examples
  pass plain and strict checks.
- The `bin/fsmgen` import map and canonical Knowledge Map fact match the live
  transitive closure and every selected measured source count.
- Focused checks, mdBook, doctrines, and diff hygiene pass without residue.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `STARTUP-INTEGRITY-REPAIR-AUG09`
  Status: `active`
  Goal: `Restore the exact test, mdBook, and maintained entrypoint-architecture truths found stale by the August 9 startup audit.`
  Children: `STARTUP-INTEGRITY-REPAIR-AUG09.1, STARTUP-INTEGRITY-REPAIR-AUG09.2, STARTUP-INTEGRITY-REPAIR-AUG09.3, STARTUP-INTEGRITY-REPAIR-AUG09.4`

- ID: `STARTUP-INTEGRITY-REPAIR-AUG09.1`
  Status: `done`
  Goal: `Activate the bounded startup-integrity repair owner from the clean baseline.`
  Acceptance: `Task/index/Memory continuity records the exact three-repair sequence before maintained test, book, map, or fact content changes.`
  Verification: `Activated from clean 895ea33bd. Task integrity passes at four active trees / 921 nodes; Memory passes at 39 lines; Knowledge Map passes at 1,105 facts / 5,713 questions / 5,879 occurrences / 118 shards; relative paths, live-document containment, full doctrines, and diff hygiene pass. Maintained tests, book, map, fact, runtime, and generated artifacts remain unchanged.`
  Commit: `STARTUP-INTEGRITY-REPAIR-AUG09.1: activate startup integrity repairs`

- ID: `STARTUP-INTEGRITY-REPAIR-AUG09.2`
  Status: `done`
  Goal: `Repair the stale direct-VHDL HIAL determinism lock exposed by the startup smoke gate.`
  Acceptance: `The lock changes only from the pre-normalization 18,380-byte SHA-256 to the current intentional 18,392-byte SHA-256; exact historical and current-output probes plus focused HIAL/VIAL tests prove the cause and result.`
  Verification: `Startup reproduced t/1551 at line 312: expected a82f42e... but generated ab668d3.... Historical backend injection measured the pre-a0e7149d5 output at 18,380 bytes / a82f42e...; live generation measures 18,392 bytes / ab668d3.... The exact diff contains only intended identifier normalization and typed equality/boolean lowering. Guarded focused tests pass: Files=5, Tests=93.`
  Commit: `STARTUP-INTEGRITY-REPAIR-AUG09.2: repair HIAL VHDL determinism lock`

- ID: `STARTUP-INTEGRITY-REPAIR-AUG09.3`
  Status: `done`
  Goal: `Restore canonical composition-wiring guidance and runnable cookbook examples.`
  Acceptance: `Recipe prose and examples use canonical '(source target)' or '(connect source target)' forms, describe '/source/target/' only as default-mode compatibility, and pass cookbook extraction plus strict-mode composition gates.`
  Verification: `Recipes 4/5 use canonical list wiring; recipe 4 also uses strict-supported reset and assignment forms. Both pass exact strict --check-json probes. Cookbook/default, strict-wiring, composition-parser/diagnostic, ISF-book, and feature-matrix tests pass: Files=6, Tests=406. All 52 mdBook chapters test and the 87-file repository-local build succeeds; output is removed exactly.`
  Commit: `STARTUP-INTEGRITY-REPAIR-AUG09.3: restore canonical cookbook wiring`

- ID: `STARTUP-INTEGRITY-REPAIR-AUG09.4`
  Status: `pending`
  Goal: `Remeasure and refresh the maintained bin/fsmgen import map and canonical fact.`
  Acceptance: `The canonical closure remains exact at 254 files / 253 packages, every selected source line count and largest-file entry matches live source, the canonical fact and generated shard agree, and documentation/doctrine gates pass.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-08-09`: One tree owns three independently committed audit repairs.
- `2026-08-09`: Commit `a0e7149d5` intentionally changed the selected direct
  VHDL output through identifier normalization plus typed equality/boolean
  lowering, but `t/1551` retained its older exact hash.
- `2026-08-09`: The May 29 cookbook slice reintroduced slash-only guidance
  after the May 24 strict cut; canonical list forms remain authoritative.
- `2026-08-09`: Import topology is unchanged; measurements are stale.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` plus the May 24 strict-wiring and May 29 cookbook task histories prove that the later runnable recipe slice reintroduced slash-only guidance after canonical strict forms shipped; the staged authority checker also named the exact changed `shipped_behavior` aggregate.
- [x] **ADDRESSED (verified)** — Recipes 4/5 pass exact strict `--check-json` probes after canonical list wiring; recipe 4 also uses strict-supported reset/assignment forms. The authority records 52 files / 48,570-line / 2,572,780-byte baseline plus the exact +2-line / +134-byte delta.
- [x] **NO REGRESSION** — Guarded book/composition tests report `All tests successful. Files=6, Tests=406`; all 52 chapter tests and the 87-file build pass, and the staged doctrine gate reports `[doctrine] all doctrine checks passed`.
