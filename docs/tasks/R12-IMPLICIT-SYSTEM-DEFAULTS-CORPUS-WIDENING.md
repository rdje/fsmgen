# R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING: Implicit System Defaults Corpus Widening

## Metadata

- Tree ID: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused direct implicit `+system` default behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change explicit `+system` reset semantics or legacy reset-name
  compatibility.
- Do not promote multi-child composition implicit-system auto-wiring in this
  slice; that can be tracked as a separate bounded corpus entry if selected.
- Do not change ISF actor timing defaults.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes a direct `?fsm` source that omits
  `+system` into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations proving that omitted direct-root system metadata emits `clk`,
  async active-low `rst_n`, and reset tests using `!rst_n`.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for direct implicit system defaults`
  Children: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1`, `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2`

- ID: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the implicit system defaults corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1: select implicit system defaults widening`

- ID: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for direct implicit system defaults`
  Acceptance: `named fixture/catalog entry covers an omitted +system direct FSM with strict-supported checks and HDL-shape expectations for clk/rst_n async active-low lowering`
  Verification: `./bin/fsmgen --strict --quiet -o /tmp/implicit_system_defaults.sv t/corpus/implicit_system_defaults.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/74-language-contract-implicit-system-defaults.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2: widen implicit system defaults corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2` | `done` | Promoted already-focused direct implicit system-default behavior after ownership was committed. |

## Decisions

- `2026-05-21`: Selected direct implicit system defaults because
  [t/74-language-contract-implicit-system-defaults.t](../../t/74-language-contract-implicit-system-defaults.t)
  already locks the direct omitted-`+system` contract for `clk`, async
  active-low `rst_n`, and `!rst_n` reset tests, while maintained positive
  system-contract corpus entries currently cover explicit `+system` contracts
  only.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-21` | `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2` | `./bin/fsmgen --strict --quiet -o /tmp/implicit_system_defaults.sv t/corpus/implicit_system_defaults.fsm`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/74-language-contract-implicit-system-defaults.t`; `prove -Iperl t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t`; `prove -Iperl t/296-regression-corpus-supported-behavior.t t/301-check-json-supported-corpus.t t/302-normalized-semantic-json.t t/303-normalized-semantic-json-supported-corpus.t t/297-capability-manifest.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1` | `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1: select implicit system defaults widening` | Selection leaf; no compiler behavior changed. |
| `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2` | `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2: widen implicit system defaults corpus` | Added supported-smoke fixture/catalog coverage; no parser or HDL-generation behavior changed. |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
- `2026-05-21`: Added a maintained supported-smoke corpus entry for direct
  implicit system defaults, including strict-supported metadata, HDL-shape
  expectations, support-accounting gates, regression-corpus docs, and mdBook
  coverage.
