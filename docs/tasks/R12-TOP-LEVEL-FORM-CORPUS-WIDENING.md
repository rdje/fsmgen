# R12-TOP-LEVEL-FORM-CORPUS-WIDENING: Top-Level Form Corpus Widening

## Metadata

- Tree ID: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused unsupported top-level form failures inside structured
FSM source bodies into the maintained expected-failure regression corpus with
stable diagnostics and public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add support for future-looking top-level infix init forms such as
  `(signal := value)`.
- Do not add support for malformed bare scalar/list body items such as
  `(BROKEN 1)`.
- Do not change bare source-root handling outside a supported `?fsm` or `+fsm`
  source root.
- Do not widen composition child-source diagnostics in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected unsupported top-level form
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for unsupported top-level form failures`
  Children: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1`, `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2`

- ID: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the unsupported top-level form corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1: select top-level form widening`

- ID: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for unsupported top-level body forms`
  Acceptance: `named fixtures/catalog entries cover future-looking top-level infix init forms and malformed bare scalar body forms with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused top-level form tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2: widen top-level form corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2` shipped the selected top-level form corpus widening. |

## Decisions

- `2026-05-20`: Selected unsupported top-level infix init and malformed bare
  scalar body forms as the next R12 corpus subset because
  [t/43-language-contract-top-level-form-boundary.t](../../t/43-language-contract-top-level-form-boundary.t)
  already locks the fail-closed behavior, but those failures are not yet
  support-accounted with stable diagnostic identities.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused top-level form tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1` | `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1: select top-level form widening` | Selection leaf; no compiler behavior changed. |
| `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2` | `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2: widen top-level form corpus` | Adds two maintained unsupported top-level form expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added maintained expected-failure entries for unsupported
  top-level infix init and malformed bare scalar body forms, then closed the
  tree.
