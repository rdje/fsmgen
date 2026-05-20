# R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING: Assignment-Boundary Corpus Widening

## Metadata

- Tree ID: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused assignment-boundary failures into the maintained
expected-failure regression corpus with stable diagnostics and public report
coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not alter the supported assignment operator surface.
- Do not widen delayed-pulse or self-dependency semantics in this tree.
- Do not claim all assignment errors are exhausted; this tree covers one
  bounded subset of already-focused rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected assignment-boundary rejection
  families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for assignment-boundary failures`
  Children: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1`, `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2`

- ID: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the assignment-boundary corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1: select assignment-boundary widening`

- ID: `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for selected delayed-pulse, assignment-family conflict, and self-dependency rejection families`
  Acceptance: `named fixtures/catalog entries cover invalid delayed-pulse RHS values, mixed assignment-family conflicts, incompatible pulse-delay mixes, and illegal self-dependency families with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2` | `pending` | Focused assignment-boundary tests already cover these failures; the maintained corpus does not yet carry them as stable support-accounting entries. |

## Decisions

- `2026-05-20`: Selected assignment-boundary failures as the next R12 corpus
  subset because delayed-pulse RHS constraints, assignment-family conflicts,
  pulse-delay conflicts, and self-dependency rejections are user-visible
  diagnostics that already have focused coverage but not maintained
  expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1` | `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1: select assignment-boundary widening` | Selection leaf; no compiler behavior changed. |
| `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2` | `pending` | Implementation leaf pending. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
