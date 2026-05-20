# R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING: Nested and Compound Guard Corpus Widening

## Metadata

- Tree ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused supported nested guarded-block and compound guard
suffix behavior into the maintained supported-smoke regression corpus with
strict-supported coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed guard diagnostics or bare suffix rejection.
- Do not widen test-selector, state-DTE header, standalone-DT, or expression
  operator support accounting.
- Do not introduce new guard syntax.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes nested guarded blocks, compound list-form
  guards, assignment suffix guards, and transition suffix guards into a named
  supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for nested guard enable composition and compound suffix
  lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for supported nested and compound guard forms`
  Children: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1`, `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2`

- ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the nested and compound guard corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1: select nested compound guard widening`

- ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for nested and compound guard forms`
  Acceptance: `named fixture/catalog entry covers nested guarded blocks and compound suffix guards with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote the already-focused guard behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected nested guarded blocks and compound suffix guards
  because
  [t/29-language-contract-core-forms.t](../../t/29-language-contract-core-forms.t)
  already locks these supported forms, while the maintained `guard_shorthand`
  corpus entry intentionally covers only the simpler scalar, negated, inline
  comparison, suffix, and multibit-reduction guard shapes.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1` | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1: select nested compound guard widening` | Selection leaf; no compiler behavior changed. |
| `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
