# R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING: Plain Test-Signal Corpus Widening

## Metadata

- Tree ID: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported plain `?SIG` test-node behavior into
the maintained supported-smoke regression corpus with strict-supported
coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed plain test-signal diagnostics.
- Do not change relational branch-selector or computed selector
  support-accounting.
- Do not widen unrelated guard or transition surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported plain `?SIG` equality selectors
  into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for equality-branch lowering and branch-local assignment
  enables.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for plain ?SIG equality selectors`
  Children: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1`, `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2`

- ID: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the plain test-signal corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1: select plain test-signal widening`

- ID: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for plain test-signal selectors`
  Acceptance: `named fixture/catalog entry covers plain ?SIG equality branches with strict-supported checks and HDL-shape expectations`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/54-language-contract-test-signal-name-boundary.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2: widen plain test-signal corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2` | `done` | Promoted an already-focused supported plain test-signal surface after ownership was committed. |

## Decisions

- `2026-05-20`: Selected plain `?SIG` equality selectors as the next R12 corpus
  subset because
  [t/54-language-contract-test-signal-name-boundary.t](../../t/54-language-contract-test-signal-name-boundary.t)
  already locks HDL-compatible plain test-node names as supported while the
  maintained corpus currently records malformed plain test-signal diagnostics
  and relational branch selectors, but not the basic supported equality branch
  surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/54-language-contract-test-signal-name-boundary.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1` | `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1: select plain test-signal widening` | Selection leaf; no compiler behavior changed. |
| `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2` | `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2: widen plain test-signal corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added a maintained supported-smoke corpus entry for plain
  `?SIG` equality selectors, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
