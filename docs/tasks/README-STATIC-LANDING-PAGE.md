# README-STATIC-LANDING-PAGE: Make The Entrypoint Nearly Static

## Metadata

- Tree ID: `README-STATIC-LANDING-PAGE`
- Status: `done`
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
  Status: `done`
  Goal: `Make README.md a concise, nearly static landing page and prevent renewed growth.`
  Children: `README-STATIC-LANDING-PAGE.1, README-STATIC-LANDING-PAGE.2, README-STATIC-LANDING-PAGE.3`

- ID: `README-STATIC-LANDING-PAGE.1`
  Status: `done`
  Goal: `Activate the measured reduction and reusable-policy contract before changing README.md.`
  Acceptance: `The task-tree records the 2,353-line / 377,853-byte starting point, exact content-routing boundary, planned slices, validation scope, and rollback boundary; README.md remains unchanged; the activation is committed from a clean tree.`
  Verification: `Consulted decision 0021, its completed predecessor tree, the live README doctrine check, Knowledge Map, task-tree index, and bounded Memory. Recorded a three-leaf no-runtime plan; README.md remains byte-for-byte unchanged in this activation leaf.`
  Commit: `README-STATIC-LANDING-PAGE.1: activate nearly-static README contract`

- ID: `README-STATIC-LANDING-PAGE.2`
  Status: `done`
  Goal: `Rewrite README.md as a concise GitHub landing page and synchronize its live navigation truth.`
  Acceptance: `README.md keeps only stable objective, layer model, quick start, key commands, repository orientation, contribution invariants, and curated canonical navigation; exhaustive indexes, status narration, and duplicated detailed contracts are removed rather than relocated; stale live/canonical references are corrected in the README, roadmap/bootstrap guidance, and mdBook; all links and examples are verified.`
  Verification: `README.md is reduced from 2,353 lines / 377,853 bytes to 242 lines / 9,566 bytes. It keeps the stable objective, IAL model, backend boundary, requirements, tested quick start, CLI discovery, curated documentation, canonical truth routing, concise repository orientation, development workflow, maintenance rule, and license. The 1,362-line hand-maintained Markdown inventory plus detailed implementation/status narration were deleted without relocation; canonical book/task/decision/fact/git/source surfaces remain linked. ROADMAP_V2.md, SESSION_BOOTSTRAP.md, and mdBook chapters 00/90 now route live status to MEMORY.md plus docs/TASK_TREE.md and identify ROADMAP_STATUS.md as frozen. Every retained README local link exists. Executable check, IAL1 schedule, IAL2 schedule, manifest, and semantic examples pass. Focused docs verification passes 329 tests across t/1256, t/1303, t/1305, t/1332, and t/1414 under the RAM guard. The mdBook builds and generated docs/book/book is removed. Diff hygiene passes; runtime behavior is unchanged.`
  Commit: `README-STATIC-LANDING-PAGE.2: reduce README to stable landing page`

- ID: `README-STATIC-LANDING-PAGE.3`
  Status: `done`
  Goal: `Add a small project-neutral README maintenance standard and ratchet mechanical enforcement to the reduced shape.`
  Acceptance: `A self-contained git-tracked Markdown standard explains the stable landing-page contract, dynamic-content routing, line/byte budgets, deterministic pre-commit/CI enforcement, exception rule, and adoption checklist without FSMGen-specific assumptions; FSMGen's doctrine check enforces the reduced budget; doctrine/tooling docs, decision record, task tree, Memory, mdBook when relevant, and Knowledge Map are synchronized.`
  Verification: `Added the self-contained 61-line / 2,425-byte README_POLICY.md with a project-neutral content contract, routing table, line/byte guard, pre-commit/CI rule, explicit cap-increase boundary, and six-step adoption checklist. Decision 0024 records FSMGen's nearly-static contract and 300-line / 16,384-byte budgets; the canonical fact card is indexed by the regenerated Knowledge Map at 1,065 facts / 5,482 question keys. scripts/check_readme_entrypoint.sh now checks lines, bytes, and chronology; its default check passes at README.md 244 lines / 9,679 bytes. Override probes at line cap 243 and byte cap 9,678 both fail with actionable routing guidance. README, doctrine registry documentation, toolbox, decision index, and mdBook reference map link the standard. README local links, shell syntax, Knowledge Map generation/check, and mdBook build pass; generated docs/book/book is removed. Diff hygiene and all six registered doctrine checks pass; runtime behavior is unchanged.`
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
- `2026-07-30`: The reduced landing page is 242 lines / 9,566 bytes. Its
  quick-start commands and every retained local link were verified before
  closeout; detailed dynamic content remains in existing canonical homes.
- `2026-07-30`: The reusable standard is deliberately one Markdown file rather
  than a copied FSMGen-specific script. It specifies a portable check contract
  and adoption steps, while each adopting repository selects and owns its caps.
- `2026-07-30`: FSMGen's reviewed post-link baseline is 244 lines / 9,679
  bytes; fixed 300-line / 16,384-byte ceilings leave modest headroom and may
  increase only through an explicit reviewed landing-contract decision.

## Blockers

- None.
