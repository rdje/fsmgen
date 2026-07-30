# MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC: Align AHB BUSY-Count Residue

## Metadata

- Tree ID: `MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC`
- Status: `active`
- Roadmap lane: `roadmap/documentation alignment / IAL2 AHB requester`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Align Chapter 16c's stale future/residue wording with the already shipped
canonical decimal AHB requester `busy-beats` range `2..16`, without changing
product behavior or overstating the public fixture catalog.

## Non-Goals

- Do not change AHB requester parsing, lowering, generated HDL, runtime
  behavior, public sources, support accounting, or APIs.
- Do not add one public fixture per literal count in `5..16`.
- Do not widen admission above 16 or add symbolic, policy, runtime, or random
  throttling or multiple insertion points.

## Acceptance Criteria

- Chapter 16c distinguishes exact-one-through-four catalog fixtures from the
  generic shipped canonical literal range `5..16` without per-count fixtures.
- Values above 16 and all other existing BUSY-insertion residue remain explicit.
- Focused chapter/book/status/path checks, full mdBook test/build, Knowledge
  Map, memory, diff, and doctrine gates pass from repository-local same-volume
  paths.
- The task index and bounded resume pointer are current, and `.1` is committed
  through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC`
  Status: `active`
  Goal: `Synchronize Chapter 16c's generalized AHB requester BUSY-count residue.`
  Children: `MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1`

- ID: `MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1`
  Status: `active`
  Goal: `Correct the stale counts-beyond-four residue without behavior changes.`
  Acceptance: `Change only Chapter 16c's contradictory residue bullet so exact-one-through-four fixtures and generic literal 5..16 support are distinct; preserve above-16 and every other deferred boundary.`
  Verification: `Activated only after clean parent selector commit 6e1c73d8c. Activation changes task, selector, roadmap, mdBook backlog, Knowledge Map fact, Memory, and changelog continuity only. Chapter 16c's stale residue, code, sources, tests, support accounting, artifacts, APIs, HDL/runtime, and every broader owner remain unchanged until this activation commits cleanly. Feature-backlog status, live-book-path, and relative-path audits pass with Files=3, Tests=40; Knowledge Map generation/check passes at 1074 facts / 5534 question keys; memory architecture passes with MEMORY.md at 45 lines; the 72-file mdBook HTML build passes and its exact repository-local output is removed; diff hygiene passes.`
  Commit: `MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.1: activate AHB busy-count residue sync`

## Decisions

- `2026-07-30`: Parent selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.840`
  proved the stale bullet contradicts the lowerer, canonical behavior record,
  and Chapter 16c's current/history sections, then selected `.1` as the
  smallest no-behavior truth repair.
- `2026-07-30`: Clean selector commit `6e1c73d8c` activates `.1`
  continuity-only. The stale Chapter 16c paragraph remains unchanged until
  this activation commit is clean.

## Blockers

- None; after this activation commits cleanly, edit only the selected Chapter
  16c residue and close the leaf.
