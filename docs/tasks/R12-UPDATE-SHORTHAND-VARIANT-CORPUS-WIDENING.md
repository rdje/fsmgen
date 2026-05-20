# R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING: Update-Shorthand Variant Corpus Widening

## Metadata

- Tree ID: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported update-shorthand variant behavior into
the maintained supported-smoke regression corpus with strict-supported
coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed update-shorthand target or tail diagnostics in this
  tree.
- Do not change the canonical assignment-family lowering for `+=` or `-=`.
- Do not widen unrelated assignment operators or delayed-pulse semantics.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported `+=` / `-=` shorthand variants
  with implicit and explicit deltas into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for update-shorthand variants`
  Children: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1`, `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.2`

- ID: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the update-shorthand variant corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1: select update-shorthand variant widening`

- ID: `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for update-shorthand variants`
  Acceptance: `named fixture/catalog entry covers implicit and explicit +={delta}/-={delta} update shorthand with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.2` | `pending` | Promotes an already-focused supported assignment-surface variant after ownership is committed. |

## Decisions

- `2026-05-20`: Selected supported update-shorthand variants as the next R12
  corpus subset because
  [t/60-language-contract-update-shorthand-variants.t](../../t/60-language-contract-update-shorthand-variants.t)
  already locks the accepted `+=` / `-=` lowering for implicit and explicit
  deltas, while the maintained corpus currently accounts for the malformed
  update-shorthand side but not the supported variant surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1` | `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1: select update-shorthand variant widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
