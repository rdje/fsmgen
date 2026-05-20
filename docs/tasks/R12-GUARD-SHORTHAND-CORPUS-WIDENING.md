# R12-GUARD-SHORTHAND-CORPUS-WIDENING: Guard-Shorthand Corpus Widening

## Metadata

- Tree ID: `R12-GUARD-SHORTHAND-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported guard-shorthand behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed guard-condition diagnostics in this tree.
- Do not change state-DT header guard semantics already covered by the
  state-DTE guard corpus tree.
- Do not widen unrelated relational operator chains or assignment surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported guard shorthand and suffix guard
  forms into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for truthiness, negated truthiness, inline comparison, and
  suffix-guard lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-GUARD-SHORTHAND-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for guard shorthand`
  Children: `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1`, `R12-GUARD-SHORTHAND-CORPUS-WIDENING.2`

- ID: `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the guard-shorthand corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1: select guard-shorthand widening`

- ID: `R12-GUARD-SHORTHAND-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for guard shorthand`
  Acceptance: `named fixture/catalog entry covers scalar truthiness, negated truthiness, inline comparison, and suffix-guard shorthand with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-GUARD-SHORTHAND-CORPUS-WIDENING.2` | `pending` | Promotes an already-focused supported guard surface after ownership is committed. |

## Decisions

- `2026-05-20`: Selected guard shorthand as the next R12 corpus subset because
  [t/39-language-contract-guard-shorthand.t](../../t/39-language-contract-guard-shorthand.t)
  already locks scalar truthiness, negated truthiness, inline comparison, and
  suffix guard lowering, while the maintained supported-smoke corpus does not
  yet carry a dedicated guard-shorthand entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1` | `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1: select guard-shorthand widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
