# R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING: Composition Child Structure Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed composition child-entry structure diagnostics
into the maintained expected-failure regression corpus with stable diagnostics
and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change `?ports`, `?wiring`, generated-child, external RTL, or `.rtlif`
  semantic validation after the child-entry list has parsed.
- Do not widen every composition parser diagnostic; this tree covers the
  bounded child-entry structure subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes empty child entries, non-string child
  headers, and representative dotted-pair child payloads into named
  expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for malformed composition child-entry structure diagnostics`
  Children: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1`, `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition child-structure corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1: select child-structure widening`

- ID: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for malformed composition child-entry structure`
  Acceptance: `named fixtures/catalog entries cover empty child entries, non-string child headers, and dotted-pair child payloads with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/128-composition-child-structure-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2: widen child-structure corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The bounded child-entry structure corpus-widening tree is complete. |

## Decisions

- `2026-05-22`: Selected composition child-entry structure because
  [t/128-composition-child-structure-diagnostics.t](../../t/128-composition-child-structure-diagnostics.t)
  already locks explicit diagnostics for empty entries, non-string headers, and
  dotted-pair payloads, while maintained composition-contract corpus coverage
  currently accounts for later child source and metadata failures rather than
  this earlier child-entry list shape boundary.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/128-composition-child-structure-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1` | `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1: select child-structure widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2` | `41c26a6d R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2: widen child-structure corpus` | `completion commit` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added seven maintained expected-failure fixtures/catalog
  entries for empty child entries, non-string child headers, and dotted-pair
  payloads across `?fsmc`, `?wiring`, `?ports`, `?dtc`, and `?rtl`; added
  stable diagnostic-code metadata; synchronized corpus docs and the mdBook.
