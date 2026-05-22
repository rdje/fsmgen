# R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING: Wrong-Kind Child Source Corpus Widening

## Metadata

- Tree ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused generated-child wrong-kind source realization failures
into the maintained expected-failure regression corpus with stable diagnostics
and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change generated-child source resolution, search-path semantics, or
  source-kind classification.
- Do not widen missing-child-source or RTL metadata diagnostics; those already
  have dedicated corpus coverage.
- Do not claim all composition child-source failures are exhausted; this tree
  covers one bounded wrong-kind subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes wrong-kind generated-child source
  realization failures into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata, compiled diagnostic
  regex metadata, and any required search-path metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for wrong-kind generated-child source realization`
  Children: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1`, `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the wrong-kind child-source corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1: select wrong-kind child-source widening`

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for wrong-kind generated-child source realization`
  Acceptance: `named fixtures/catalog entries cover ?fsmc resolving to a standalone-DT child and ?dtc resolving to an FSM child with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/115-composition-child-source-diagnostics.t t/244-composition-child-resolution-diagnostic-context.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2: widen wrong-kind child-source corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2` | `done` | Promoted focused wrong-kind generated-child source diagnostics into maintained corpus coverage. |

## Decisions

- `2026-05-22`: Selected wrong-kind generated-child source realization because
  focused diagnostics already cover `?fsmc` resolving to standalone-DT source
  and `?dtc` resolving to FSM source, while maintained composition-contract
  corpus coverage currently isolates missing child sources and RTL metadata
  failures but not wrong-kind resolved generated-child files.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/115-composition-child-source-diagnostics.t t/244-composition-child-resolution-diagnostic-context.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1: select wrong-kind child-source widening` | `selection leaf; no compiler behavior changed` |
| `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2: widen wrong-kind child-source corpus` | `added expected-failure fixture/catalog coverage; no parser or HDL-generation behavior changed` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added maintained expected-failure corpus coverage for
  wrong-kind external generated-child source realization in both `?fsmc` and
  `?dtc` directions, with stable diagnostic-code metadata and synchronized
  docs.
