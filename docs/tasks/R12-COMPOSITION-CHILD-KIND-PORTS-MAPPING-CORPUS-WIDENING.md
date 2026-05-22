# R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING: Composition Child Kind And Ports Mapping Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused unsupported composition child-kind and legacy `?ports`
mapping directive diagnostics into the maintained expected-failure regression
corpus with stable diagnostics and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change duplicate declaration, explicit-link, endpoint-shape, or
  topology diagnostics in this tree.
- Do not revive legacy `?ports` mapping directives; this tree records the
  current explicit top-port declaration boundary as maintained truth.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes the unsupported child-kind diagnostic and
  the legacy `?ports` mapping directive diagnostic into named expected-failure
  catalog entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for unsupported child-kind and legacy ports-mapping composition diagnostics`
  Children: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1`, `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the unsupported child-kind and ports-mapping corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1: select child-kind ports-mapping widening`

- ID: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for unsupported composition child kinds and legacy ports mapping directives`
  Acceptance: `named fixtures/catalog entries cover unsupported child kinds and legacy ports mapping directives with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/129-composition-unsupported-child-diagnostics.t`; `prove -Iperl t/127-composition-ports-mapping-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2: widen child-kind ports-mapping corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The bounded child-kind and ports-mapping corpus-widening tree is complete. |

## Decisions

- `2026-05-22`: Selected unsupported child-kind and legacy `?ports` mapping
  diagnostics because
  [t/129-composition-unsupported-child-diagnostics.t](../../t/129-composition-unsupported-child-diagnostics.t)
  and
  [t/127-composition-ports-mapping-diagnostics.t](../../t/127-composition-ports-mapping-diagnostics.t)
  already lock the current parser boundary through pipeline and CLI, while
  maintained composition-contract corpus coverage now accounts for child-entry
  structure, child source realization, generated-child source shape, external
  RTL source shape, and `.rtlif` metadata boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/129-composition-unsupported-child-diagnostics.t`; `prove -Iperl t/127-composition-ports-mapping-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1` | `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1: select child-kind ports-mapping widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2` | `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2: widen child-kind ports-mapping corpus` | `pending commit` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added maintained expected-failure fixtures/catalog entries for
  unsupported child kinds and legacy `?ports` mapping directives; added stable
  diagnostic-code metadata; synchronized corpus docs and the mdBook.
