# R12-LANGUAGE-CONTRACT-CORPUS-WIDENING: Language-Contract Corpus Widening

## Metadata

- Tree ID: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused `.fsm` language-contract rejection behavior into the
maintained regression corpus so those failures are support-accounted, stable
diagnostic-coded, and covered through pipeline, CLI, check JSON, and normalized
semantic JSON surfaces.

## Non-Goals

- Do not change parser acceptance or generation behavior in the selection leaf.
- Do not add a new strict-mode compatibility cut in this tree.
- Do not widen ISF behavior or `.isf` documentation in this tree.
- Do not claim broad language-contract exhaustion; this tree covers one bounded
  corpus-widening slice.

## Acceptance Criteria

- The task tree is active before any fixture, test, source, generated-artifact,
  or config changes for this corpus widening.
- The implementation leaf adds a bounded set of named language-contract
  expected-failure corpus entries for already-focused rejection families.
- Each new expected-failure entry has a known stable diagnostic code, compiled
  diagnostic regex, and correct support-accounting coverage bucket.
- Pipeline, CLI, check JSON, and normalized semantic JSON regression-corpus
  checks pass for the widened catalog.
- Live docs, regression-corpus docs, roadmap status, and mdBook content are
  synchronized if the user-facing support-accounting surface changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for focused language-contract rejections`
  Children: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1`, `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2`

- ID: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the bounded R12 language-contract corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree, current frontier, non-goals, acceptance criteria, and live status updates identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1: select corpus widening`

- ID: `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure corpus entries for selected language-contract rejection families`
  Acceptance: `named fixtures/catalog entries cover unsupported top-level source or directive forms, generic/template placeholder forms, and bare condition suffix forms with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2` | `pending` | R12 still needs wider expected-failure coverage beyond the current malformed-size/direct-generation/composition families, and focused tests already identify language-contract rejection families that should become support-accounted corpus entries. |

## Decisions

- `2026-05-20`: Selected R12 corpus widening instead of a new parser behavior
  change because the roadmap's current measurable gap is support-accounting
  breadth. The first implementation leaf should promote already-focused
  language-contract rejections into the maintained catalog rather than invent
  new language semantics.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1` | `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1: select corpus widening` | Selection leaf; no compiler behavior changed. |
| `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created the task tree and selected the next implementation
  frontier.
