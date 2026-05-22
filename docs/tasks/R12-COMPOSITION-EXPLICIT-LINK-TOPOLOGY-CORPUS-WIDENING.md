# R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING: Composition Explicit-Link Topology Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused missing explicit `?wiring` topology diagnostic into
the maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change composition lane selection.
- Do not infer wiring for multi-child composition tops in this tree.
- Do not change generated HDL for already-supported composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes the missing explicit `?wiring` rejection
  into a named expected-failure catalog entry.
- The new entry records stable diagnostic-code metadata and compiled diagnostic
  regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for missing explicit composition wiring diagnostics`
  Children: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1`, `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition explicit-link topology corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1: select explicit-link topology widening`

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained expected-failure entry for missing explicit composition wiring`
  Acceptance: `named fixture/catalog entry covers missing explicit '?wiring' rejection with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/109-composition-explicit-link-topology-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2: widen explicit-link topology corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2` | `done` | Promoted focused missing explicit `?wiring` diagnostics into maintained corpus coverage. |

## Decisions

- `2026-05-22`: Selected explicit-link topology because
  [t/109-composition-explicit-link-topology-diagnostics.t](../../t/109-composition-explicit-link-topology-diagnostics.t)
  already locks the missing explicit `?wiring` diagnostic, while maintained
  composition-contract corpus coverage now accounts for child-entry,
  child-kind, ports shape/mapping, duplicate declaration, child-source,
  generated-child source-shape, external RTL source-shape, `.rtlif` metadata,
  and target-support boundaries.
- `2026-05-22`: Kept the C2 explicit-link boundary fail-closed. Multi-child
  composition topologies that require data routing must author `?wiring`; the
  corpus now records the no-`?wiring` topology as a stable expected failure.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/109-composition-explicit-link-topology-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1: select explicit-link topology widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2: widen explicit-link topology corpus` | `added missing explicit wiring to maintained expected-failure corpus coverage` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added the missing explicit `?wiring` fixture/catalog entry,
  stable diagnostic-code metadata, regression-corpus docs, and mdBook
  composition/error coverage; closed the task tree.
