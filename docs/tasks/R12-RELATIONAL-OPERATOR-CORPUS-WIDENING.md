# R12-RELATIONAL-OPERATOR-CORPUS-WIDENING: Relational Operator Corpus Widening

## Metadata

- Tree ID: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported relational-operator chain and word-alias
behavior into the maintained supported-smoke regression corpus with
strict-supported coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed relational/operator diagnostics in this tree.
- Do not widen guard-shorthand support-accounting, which is already owned by
  the guard-shorthand corpus tree.
- Do not change assignment, transition, or expression factoring semantics.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported n-ary relational chains and word
  aliases into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for comparison-chain and alias lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for relational operator chains and aliases`
  Children: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1`, `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2`

- ID: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the relational-operator corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1: select relational-operator widening`

- ID: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for relational operator chains and aliases`
  Acceptance: `named fixture/catalog entry covers n-ary relational chains, word aliases, unary not alias, and guarded relational chain lowering with strict-supported checks and HDL-shape expectations`
  Verification: `perl -Iperl -c` for touched support/tests; focused relational-operator tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2: widen relational-operator corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2` shipped the selected relational-operator corpus widening. |

## Decisions

- `2026-05-20`: Selected relational operator chains and word aliases as the
  next R12 corpus subset because
  [t/44-language-contract-relational-operators.t](../../t/44-language-contract-relational-operators.t)
  already locks n-ary relational chain lowering, `eq` / `ge` aliases, unary
  `not`, and guarded relational-chain lowering, while the maintained
  supported-smoke corpus does not yet carry a dedicated relational-operator
  entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused relational-operator tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1` | `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1: select relational-operator widening` | Selection leaf; no compiler behavior changed. |
| `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2` | `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2: widen relational-operator corpus` | Adds one maintained supported relational-operator smoke entry. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added a maintained supported-smoke entry for relational
  operator chains and aliases, then closed the tree.
