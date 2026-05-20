# R12-STANDALONE-DT-GUARD-CORPUS-WIDENING: Standalone-DT Guard Corpus Widening

## Metadata

- Tree ID: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported standalone DT classification and
standalone DT DTE-guard behavior into the maintained supported-smoke
regression corpus with strict-supported coverage and public
support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change regular-state DTE guard support-accounting.
- Do not change malformed standalone DT body/name diagnostics.
- Do not widen unrelated transition, guard-shorthand, or composition surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported standalone DT classification and
  DTE guards into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for standalone DT enables, guarded DT enable emission, and
  output-enable gating.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for standalone DT classification and guards`
  Children: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1`, `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.2`

- ID: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the standalone DT guard corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1: select standalone DT guard widening`

- ID: `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for standalone DT guards`
  Acceptance: `named fixture/catalog entry covers unguarded and guarded standalone DT blocks with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.2` | `pending` | Promotes an already-focused supported standalone DT surface after ownership is committed. |

## Decisions

- `2026-05-20`: Selected standalone DT classification and DTE guards as the
  next R12 corpus subset because
  [t/48-language-contract-standalone-dt-classification.t](../../t/48-language-contract-standalone-dt-classification.t)
  already locks standalone DT state classification, always-on standalone DT
  enables, guard-expression lowering, and guarded output-enable boundaries,
  while the maintained corpus currently records malformed standalone DT
  diagnostics but not this supported standalone DT surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1` | `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1: select standalone DT guard widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
