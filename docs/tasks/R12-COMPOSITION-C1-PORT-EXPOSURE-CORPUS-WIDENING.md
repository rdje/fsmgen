# R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING: Composition C1 Port Exposure Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused C1 passthrough exposure diagnostics into the
maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change single-child passthrough inference.
- Do not relax top/child port direction, width, or name compatibility.
- Do not change generated HDL for already-supported C1 composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes missing child exposure, unknown top-port,
  width mismatch, and direction mismatch C1 rejections into named
  expected-failure catalog entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for C1 passthrough exposure diagnostics`
  Children: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1`, `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition C1 port-exposure corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1: select C1 port exposure widening`

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for C1 passthrough exposure mismatches`
  Acceptance: `named fixtures/catalog entries cover missing exposure, unknown top-port, width mismatch, and direction mismatch with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/111-composition-c1-port-exposure-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2: widen C1 port exposure corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2` | `done` | Promoted focused C1 passthrough exposure diagnostics into maintained corpus coverage. |

## Decisions

- `2026-05-22`: Selected C1 passthrough exposure because
  [t/111-composition-c1-port-exposure-diagnostics.t](../../t/111-composition-c1-port-exposure-diagnostics.t)
  already locks missing exposure, unknown explicit top-port, width mismatch,
  and direction mismatch diagnostics, while maintained composition-contract
  corpus coverage now accounts for child-entry, child-kind, ports
  shape/mapping, duplicate declaration, explicit-link topology, child-source,
  generated-child source-shape, external RTL source-shape, `.rtlif` metadata,
  and target-support boundaries.
- `2026-05-22`: Kept C1 passthrough exposure fail-closed. Explicit `?ports`
  must accurately expose the realized child interface; FSMGen rejects missing
  child exposure, unknown top ports, and direction/width mismatches before HDL
  emission.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/111-composition-c1-port-exposure-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1: select C1 port exposure widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2: widen C1 port exposure corpus` | `added four C1 passthrough exposure failures to maintained expected-failure corpus coverage` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added C1 passthrough exposure fixture/catalog entries, stable
  diagnostic-code metadata, regression-corpus docs, and mdBook
  composition/error coverage; closed the task tree.
