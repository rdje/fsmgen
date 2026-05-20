# R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING: Compound Update Variants Corpus Widening

## Metadata

- Tree ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING`
- Status: `done`
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
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for supported compound update variants`
  Children: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1`, `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2`

- ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the compound update variant corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1: select compound update variant widening`

- ID: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for compound update variants`
  Acceptance: `named fixture/catalog entry covers ++, --, compact +=N/-=N, and inline compound modifiers with strict-supported checks and HDL-shape expectations`
  Verification: `./bin/fsmgen --strict --quiet -o /tmp/compound_update_variants.sv t/corpus/compound_update_variants.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/29-language-contract-core-forms.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2: widen compound update variant corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` | `done` | Promoted already-focused compound update behavior after ownership was committed. |

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
| `2026-05-21` | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` | `./bin/fsmgen --strict --quiet -o /tmp/compound_update_variants.sv t/corpus/compound_update_variants.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/29-language-contract-core-forms.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1` | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1: select compound update variant widening` | Selection leaf; no compiler behavior changed. |
| `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` | `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2: widen compound update variant corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
- `2026-05-21`: Added a maintained supported-smoke corpus entry for compound
  update variants, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
