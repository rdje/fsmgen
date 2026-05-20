# R12-MALFORMED-FORM-CORPUS-WIDENING: Malformed-Form Corpus Widening

## Metadata

- Tree ID: `R12-MALFORMED-FORM-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote another bounded set of already-focused `.fsm` malformed-form
language-contract failures into the maintained expected-failure regression
corpus, with stable diagnostic codes and public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add strict-mode compatibility cuts.
- Do not widen ISF behavior or `.isf` documentation in this tree.
- Do not claim language-contract exhaustion; this tree handles one malformed
  source/body/test-form subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected malformed source/body/test-form
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-MALFORMED-FORM-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for malformed source/body/test forms`
  Children: `R12-MALFORMED-FORM-CORPUS-WIDENING.1`, `R12-MALFORMED-FORM-CORPUS-WIDENING.2`

- ID: `R12-MALFORMED-FORM-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the malformed-form corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-MALFORMED-FORM-CORPUS-WIDENING.1: select malformed-form widening`

- ID: `R12-MALFORMED-FORM-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for malformed source/body/test-form rejection families`
  Acceptance: `named fixtures/catalog entries cover malformed top-level source roots, malformed action/guard forms, malformed test branches, and malformed test selectors with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-MALFORMED-FORM-CORPUS-WIDENING.2` | `pending` | R12 still needs wider expected-failure coverage beyond the current malformed-size, top-level directive/source, generic/template, bare-suffix, direct-generation, and composition families. |

## Decisions

- `2026-05-20`: Selected malformed source/body/test forms as the next R12
  corpus-widening subset because focused tests already define targeted
  rejection behavior, but those failure families are not yet maintained
  support-accounting entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-MALFORMED-FORM-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-MALFORMED-FORM-CORPUS-WIDENING.1` | `R12-MALFORMED-FORM-CORPUS-WIDENING.1: select malformed-form widening` | Selection leaf; no compiler behavior changed. |
| `R12-MALFORMED-FORM-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
