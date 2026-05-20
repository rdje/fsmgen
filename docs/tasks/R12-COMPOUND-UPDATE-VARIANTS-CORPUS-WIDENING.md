# R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING: Compound Update Variants Corpus Widening

## Metadata

- Tree ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused supported compound update variants into the maintained
supported-smoke regression corpus with strict-supported coverage and public
support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed update-shorthand diagnostics, nested-target
  rejection, or malformed inline compound modifier diagnostics.
- Do not widen unrelated assignment-pair, guard, or expression-operator
  support accounting.
- Do not introduce new update shorthand syntax.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes `++`, `--`, compact `+=N` / `-=N`, and
  inline `(+= N)` / `(-= N)` modifiers into a named supported-smoke catalog
  entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for the normalized update arithmetic and preserved assignment
  families.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for supported compound update variants`
  Children: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1`, `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2`

- ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the compound update variant corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1: select compound update variant widening`

- ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for compound update variants`
  Acceptance: `named fixture/catalog entry covers ++, --, compact +=N/-=N, and inline compound modifiers with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote the already-focused compound update behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected compound update variants because
  [t/29-language-contract-core-forms.t](../../t/29-language-contract-core-forms.t)
  already locks `++`, `--`, compact `+=N` / `-=N`, and inline compound
  modifiers, while the maintained `update_shorthand_variants` corpus entry
  currently covers only the standard `+=` / `-=` forms with implicit and
  separated explicit deltas.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1` | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1: select compound update variant widening` | Selection leaf; no compiler behavior changed. |
| `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
