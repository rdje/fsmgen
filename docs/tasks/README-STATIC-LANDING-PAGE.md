# README-STATIC-LANDING-PAGE: Make The Entrypoint Nearly Static

## Metadata

- Tree ID: `README-STATIC-LANDING-PAGE`
- Status: `active`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow
- Activation: director-requested on `2026-07-30`.

## Goal

Turn `README.md` into a concise, nearly static GitHub landing page whose
dynamic detail is derived from existing canonical project surfaces, then add a
small project-neutral tracked standard other repositories can adopt to keep
their own README files from growing into histories or documentation catalogs.

## Measured Starting Point

- `README.md`: 2,353 lines / 377,853 bytes.
- The existing decision `0021` correctly forbids per-leaf narration, but its
  2,600-line mechanical ceiling still permits a landing page far larger than
  the director wants.
- Most size is an exhaustive documentation index and detailed public-contract
  narration already reachable through the mdBook, task trees, decision index,
  Knowledge Map, source tree, and git.

## Non-Goals

- Do not change parser, generator, CLI, HDL, protocol, support-accounting, or
  runtime behavior.
- Do not copy removed README material into a new prose blob.
- Do not freeze essential onboarding facts; route changeable facts to their
  canonical maintained surfaces.
- Do not weaken the bootstrap requirement that every harness starts at
  `README.md`.

## Task Tree

- ID: `README-STATIC-LANDING-PAGE`
  Status: `active`
  Goal: `Make README.md a concise, nearly static landing page and prevent renewed growth.`
  Children: `README-STATIC-LANDING-PAGE.1, README-STATIC-LANDING-PAGE.2, README-STATIC-LANDING-PAGE.3`

- ID: `README-STATIC-LANDING-PAGE.1`
  Status: `done`
  Goal: `Activate the measured reduction and reusable-policy contract before changing README.md.`
  Acceptance: `The task-tree records the 2,353-line / 377,853-byte starting point, exact content-routing boundary, planned slices, validation scope, and rollback boundary; README.md remains unchanged; the activation is committed from a clean tree.`
  Verification: `Consulted decision 0021, its completed predecessor tree, the live README doctrine check, Knowledge Map, task-tree index, and bounded Memory. Recorded a three-leaf no-runtime plan; README.md remains byte-for-byte unchanged in this activation leaf.`
  Commit: `README-STATIC-LANDING-PAGE.1: activate nearly-static README contract`

- ID: `README-STATIC-LANDING-PAGE.2`
  Status: `active`
  Goal: `Rewrite README.md as a concise GitHub landing page and synchronize its live navigation truth.`
  Acceptance: `README.md keeps only stable objective, layer model, quick start, key commands, repository orientation, contribution invariants, and curated canonical navigation; exhaustive indexes, status narration, and duplicated detailed contracts are removed rather than relocated; stale live/canonical references are corrected in the README, roadmap/bootstrap guidance, and mdBook; all links and examples are verified.`
  Verification: `Pending.`
  Commit: `README-STATIC-LANDING-PAGE.2: reduce README to stable landing page`

- ID: `README-STATIC-LANDING-PAGE.3`
  Status: `pending`
  Goal: `Add a small project-neutral README maintenance standard and ratchet mechanical enforcement to the reduced shape.`
  Acceptance: `A self-contained git-tracked Markdown standard explains the stable landing-page contract, dynamic-content routing, line/byte budgets, deterministic pre-commit/CI enforcement, exception rule, and adoption checklist without FSMGen-specific assumptions; FSMGen's doctrine check enforces the reduced budget; doctrine/tooling docs, decision record, task tree, Memory, mdBook when relevant, and Knowledge Map are synchronized.`
  Verification: `Pending.`
  Commit: `README-STATIC-LANDING-PAGE.3: codify reusable README growth control`

## Validation Plan

- `git diff --check`
- README link/structure checks and a seeded over-budget negative proof
- focused bootstrap, documentation-path, and README doctrine checks
- Knowledge Map generation/check
- `mdbook build docs/book`
- `scripts/check_doctrines.sh`

## Rollback Boundary

Each leaf is one documentation/doctrine commit. Removed README prose remains
recoverable in git; no replacement append-log file is created.

## Decisions

- `2026-07-30`: Treat the README as nearly static: change it only when its
  onboarding contract changes, not when project status or feature inventory
  changes.
- `2026-07-30`: Prefer deletion plus canonical links over moving duplicated
  README narration into another large file.

## Blockers

- None.
