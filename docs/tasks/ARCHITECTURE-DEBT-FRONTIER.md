# ARCHITECTURE-DEBT-FRONTIER: Architecture Debt Frontier

## Metadata

- Tree ID: `ARCHITECTURE-DEBT-FRONTIER`
- Status: `active`
- Roadmap lane: `architecture`
- Created: `2026-06-05`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Own the architecture debt items named in the 2026-06-05 remaining-work
inventory so convergence/refactor work is selected through task-tree leaves
rather than informal cleanup.

## Non-Goals

- Do not perform broad refactors without selecting an exact active leaf first.
- Do not change public behavior under an architecture-debt label without the
  same behavior, docs, and regression responsibilities as a feature leaf.
- Do not extract modules merely for aesthetics; extraction must reduce real
  complexity or stabilize a proven boundary.

## Acceptance Criteria

- Each architecture-debt backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Behavior-preserving refactors are validated with focused and broader gates
  according to blast radius.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ARCHITECTURE-DEBT-FRONTIER`
  Status: `active`
  Goal: `Track architecture convergence and extraction backlog directions.`
  Children: `ARCHITECTURE-DEBT-FRONTIER.1`,
    `ARCHITECTURE-DEBT-FRONTIER.2`,
    `ARCHITECTURE-DEBT-FRONTIER.3`

- ID: `ARCHITECTURE-DEBT-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable architecture-debt leaf from evidence.`
  Acceptance: `One architecture item is activated, explicitly deferred, or linked to a stronger prerequisite owner.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ARCHITECTURE-DEBT-FRONTIER.1: select direct backend convergence`

- ID: `ARCHITECTURE-DEBT-FRONTIER.2`
  Status: `active`
  Goal: `Converge the direct backend path toward StructuralRTLIR-to-emitter where one bounded step is safe.`
  Acceptance: `One exact backend convergence boundary is selected, implemented or deferred, documented if user-visible, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ARCHITECTURE-DEBT-FRONTIER.3`
  Status: `pending`
  Goal: `Extract large ISF parser/lowerer responsibilities only after stable families are identified.`
  Acceptance: `One exact extraction boundary is selected, implemented or deferred, and validated without behavior drift.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ARCHITECTURE-DEBT-FRONTIER.1` | `done` | Selected direct backend convergence from completed architecture evidence. |
| 2 | `ARCHITECTURE-DEBT-FRONTIER.2` | `active` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` left behavior-bearing direct-root convergence open, while `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` deferred extraction until a stable family is identified. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type.
- `2026-06-07`: Activated after `BACKEND-API-VALIDATION-FRONTIER.132` exhausted
  the active backend/API frontier and routed PNT to architecture-debt selection.
- `2026-06-07`: Selector leaf `ARCHITECTURE-DEBT-FRONTIER.1` chose
  `ARCHITECTURE-DEBT-FRONTIER.2` as the next executable lane. Evidence came from
  the completed direct-structural convergence tree's open behavior-bearing
  follow-up, the completed ISF LoweringIR extraction tree's no-extraction-yet
  outcome, and the import-tree audit's current direct-backend pressure notes.

## Open Questions

- `ARCHITECTURE-DEBT-FRONTIER.2`: Which exact direct-root behavior family is
  the first safe StructuralRTLIR convergence step beyond identity and ports?

## Blockers

- None for the active selector leaf.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `ARCHITECTURE-DEBT-FRONTIER.1` | `pending` | `pending` |
| `2026-06-07` | `ARCHITECTURE-DEBT-FRONTIER.1` | Evidence review: `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md`, `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md`, `docs/BIN_FSMGEN_IMPORT_TREE.md`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | pass; selected `ARCHITECTURE-DEBT-FRONTIER.2` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ARCHITECTURE-DEBT-FRONTIER.1` | `ARCHITECTURE-DEBT-FRONTIER.1: select direct backend convergence` | selected `.2` after direct/backend and ISF extraction evidence review |

## Changelog

- `2026-06-05`: Created proposed architecture-debt frontier owner tree.
- `2026-06-07`: Completed selector leaf `.1`; activated `.2` for direct backend
  StructuralRTLIR convergence selection.
