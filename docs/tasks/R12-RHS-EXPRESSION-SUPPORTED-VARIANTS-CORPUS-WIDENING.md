# R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING: RHS Expression Supported Variants Corpus Widening

## Metadata

- Tree ID: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused supported RHS expression variants into the maintained
supported-smoke regression corpus with strict-supported coverage and public
support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change unsupported RHS operator, malformed arity, guard-token, or
  ambiguous-literal diagnostics.
- Do not widen unrelated selector or guard support-accounting.
- Do not introduce broader expression-operator support.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes inline scalar comparison tokens and negated
  n-ary bitwise RHS operators into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for inline comparison rendering and factored `!&`, `!|`, and
  `xnor` lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for supported RHS expression variants`
  Children: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1`, `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2`

- ID: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the supported RHS expression variant corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1: select RHS expression variants widening`

- ID: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for supported RHS expression variants`
  Acceptance: `named fixture/catalog entry covers inline scalar comparison tokens plus !&, !|, and xnor RHS lowering with strict-supported checks and HDL-shape expectations`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/40-language-contract-expression-boundary.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2: widen RHS expression variants corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2` | `done` | Promoted already-focused supported RHS expression behavior after ownership was committed. |

## Decisions

- `2026-05-20`: Selected inline scalar comparisons and negated n-ary bitwise
  RHS operators because
  [t/40-language-contract-expression-boundary.t](../../t/40-language-contract-expression-boundary.t)
  already locks these supported forms, while the maintained corpus currently
  records expected failures for RHS expression errors but not these supported
  RHS expression variants.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/40-language-contract-expression-boundary.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1` | `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1: select RHS expression variants widening` | Selection leaf; no compiler behavior changed. |
| `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2` | `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2: widen RHS expression variants corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added a maintained supported-smoke corpus entry for supported
  RHS expression variants, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
