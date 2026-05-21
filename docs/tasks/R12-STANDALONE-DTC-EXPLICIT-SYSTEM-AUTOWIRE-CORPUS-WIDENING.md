# R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING: Standalone DTC Explicit System Autowire Corpus Widening

## Metadata

- Tree ID: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused `?dtc` composition auto-wiring for explicit
standalone-DT system ports into the maintained supported-smoke regression
corpus with strict-supported coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change direct standalone `?dt` explicit-system support; that is
  covered by `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING`.
- Do not change explicit `+system` reset semantics, named remapping, or legacy
  reset-name compatibility.
- Do not change generated-FSM child auto-wiring.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes a composition `?top` source with a `?dtc`
  child carrying canonical explicit `+system` metadata into a named
  supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations proving that the top exposes the explicit system ports and
  auto-wires them into the generated standalone-DT child.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for dtc explicit-system auto-wiring`
  Children: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`, `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`

- ID: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the standalone DTC explicit-system autowire corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1: select standalone DTC explicit-system autowire widening`

- ID: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for dtc explicit-system auto-wiring`
  Acceptance: `named fixture/catalog entry covers a ?dtc child with canonical explicit +system metadata with strict-supported checks and HDL-shape expectations for top/child system-port auto-wiring`
  Verification: `./bin/fsmgen --strict --quiet -o /tmp/standalone_dtc_explicit_system_autowire.sv t/corpus/standalone_dtc_explicit_system_autowire.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/134-standalone-dt-explicit-system-support.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2: widen standalone DTC explicit-system autowire corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` | `done` | Promoted already-focused `?dtc` explicit-system auto-wiring after ownership was committed. |

## Decisions

- `2026-05-21`: Selected `?dtc` explicit-system auto-wiring because
  [t/134-standalone-dt-explicit-system-support.t](../../t/134-standalone-dt-explicit-system-support.t)
  already locks composition auto-wiring of explicit standalone-DT system ports,
  while maintained positive composition corpus entries do not yet isolate the
  generated `?dtc` system-port binding path.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-21` | `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` | `./bin/fsmgen --strict --quiet -o /tmp/standalone_dtc_explicit_system_autowire.sv t/corpus/standalone_dtc_explicit_system_autowire.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/134-standalone-dt-explicit-system-support.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1` | `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1: select standalone DTC explicit-system autowire widening` | Selection leaf; no compiler behavior changed. |
| `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` | `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2: widen standalone DTC explicit-system autowire corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
- `2026-05-21`: Added a maintained supported-smoke corpus entry for `?dtc`
  explicit-system auto-wiring, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
