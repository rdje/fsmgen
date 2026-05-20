# R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING: Arithmetic and XOR Operator Corpus Widening

## Metadata

- Tree ID: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused supported arithmetic and XOR expression-operator
variants into the maintained supported-smoke regression corpus with
strict-supported coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change unsupported operator diagnostics, malformed arity diagnostics,
  or division/modulo safety handling.
- Do not widen relational operator, selector, guard, or reset-alias support
  accounting.
- Do not introduce broader expression-operator support beyond already-shipped
  behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes n-ary arithmetic and XOR operator variants
  into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for n-ary `+`, `-`, `*`, `add`, `^`, and `xor` lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for supported arithmetic and XOR operator variants`
  Children: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1`, `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2`

- ID: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the arithmetic and XOR operator corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1: select arithmetic XOR operator widening`

- ID: `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for arithmetic and XOR operator variants`
  Acceptance: `named fixture/catalog entry covers n-ary arithmetic and XOR alias lowering with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote the already-focused operator behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected n-ary arithmetic and XOR operator variants because
  [t/29-language-contract-core-forms.t](../../t/29-language-contract-core-forms.t)
  already locks these supported forms, while the maintained corpus currently
  has narrower positive operator coverage for division/modulo, concat/cat,
  relational chains, and selected RHS variants.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1` | `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1: select arithmetic XOR operator widening` | Selection leaf; no compiler behavior changed. |
| `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
