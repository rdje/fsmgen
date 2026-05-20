# R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING: Nested and Compound Guard Corpus Widening

## Metadata

- Tree ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING`
- Status: `done`
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
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for supported nested and compound guard forms`
  Children: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1`, `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2`

- ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the nested and compound guard corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1: select nested compound guard widening`

- ID: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for nested and compound guard forms`
  Acceptance: `named fixture/catalog entry covers nested guarded blocks and compound suffix guards with strict-supported checks and HDL-shape expectations`
  Verification: `./bin/fsmgen --strict --quiet -o /tmp/nested_compound_guards.sv t/corpus/nested_compound_guards.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/29-language-contract-core-forms.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2: widen nested compound guard corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` | `done` | Promoted already-focused nested and compound guard behavior after ownership was committed. |

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
| `2026-05-21` | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` | `./bin/fsmgen --strict --quiet -o /tmp/nested_compound_guards.sv t/corpus/nested_compound_guards.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/29-language-contract-core-forms.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1` | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1: select nested compound guard widening` | Selection leaf; no compiler behavior changed. |
| `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` | `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2: widen nested compound guard corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
- `2026-05-21`: Added a maintained supported-smoke corpus entry for nested
  and compound guard forms, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
