# R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING: Composition Endpoint Shape Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused composition endpoint-shape diagnostics into the
maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change declared same-name semantics for system ports.
- Do not infer aggregate member access for endpoints without declared aggregate
  types.
- Do not change generated HDL for already-supported composition links.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes shared system-port same-name rejection and
  aggregate-member endpoint rejection into named expected-failure catalog
  entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for composition endpoint-shape diagnostics`
  Children: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1`, `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition endpoint-shape corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1: select endpoint shape widening`

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for endpoint-shape rejections`
  Acceptance: `named fixtures/catalog entries cover shared system-port same-name rejection and aggregate-member endpoint rejection with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/113-composition-endpoint-shape-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2: widen endpoint shape corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2` | `done` | Promoted focused endpoint-shape diagnostics into maintained corpus coverage. |

## Decisions

- `2026-05-22`: Selected endpoint shape because
  [t/113-composition-endpoint-shape-diagnostics.t](../../t/113-composition-endpoint-shape-diagnostics.t)
  already locks declared same-name rejection on shared system ports and
  aggregate-member child endpoint rejection without declared aggregate types,
  while maintained composition-contract corpus coverage now accounts for
  child-entry, child-kind, ports shape/mapping, duplicate declaration, C1
  exposure, explicit-link topology, child-source, generated-child source-shape,
  external RTL source-shape, `.rtlif` metadata, and target-support boundaries.
- `2026-05-22`: Kept endpoint shape fail-closed. Shared system ports cannot
  use declared same-name syntax, and member/item endpoint access requires a
  declared aggregate type on the base endpoint before HDL planning.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/113-composition-endpoint-shape-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1: select endpoint shape widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2: widen endpoint shape corpus` | `added two endpoint-shape failures to maintained expected-failure corpus coverage` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added endpoint-shape fixture/catalog entries, stable
  diagnostic-code metadata, regression-corpus docs, and mdBook
  composition/error coverage; closed the task tree.
