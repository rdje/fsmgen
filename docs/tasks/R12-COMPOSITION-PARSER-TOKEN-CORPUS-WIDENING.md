# R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING: Composition Parser Token Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused composition parser token/shape diagnostics into
the maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change accepted `?ports`, `?wiring`, `+constants`, or `+enums`
  syntax.
- Do not add new composition top-symbol expression support in this tree.
- Do not change generated HDL for already-supported composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes malformed verbose `?ports`, invalid
  `?ports` tokens, non-positive `?ports` widths, malformed `?wiring` list
  items, unsupported `?wiring` tokens, malformed top `+constants` entries, and
  non-literal top `+enums` values into named expected-failure catalog entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for composition parser token and shape diagnostics`
  Children: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1`, `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition parser-token corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1: select parser token widening`

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for composition parser token and top-symbol rejections`
  Acceptance: `named fixtures/catalog entries cover the t/126 parser token diagnostic family with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/126-composition-parser-token-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2: widen parser token corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2` | `done` | Promoted focused parser token diagnostics into maintained corpus coverage after ownership was committed. |

## Decisions

- `2026-05-22`: Selected parser token widening because
  [t/126-composition-parser-token-diagnostics.t](../../t/126-composition-parser-token-diagnostics.t)
  already locks malformed `?ports`, malformed `?wiring`, malformed top
  symbol-token, and top symbol literal-support diagnostics through pipeline and
  CLI behavior, while maintained composition-contract corpus coverage now
  accounts for child-entry, child-kind, ports shape/mapping, duplicate
  declaration, C1 exposure, explicit-link topology, endpoint shape,
  child-source, generated-child source-shape, external RTL source-shape,
  `.rtlif` metadata, and target-support boundaries.
- `2026-05-22`: Completed the widening as a diagnostic-only support-accounting
  slice. The maintained corpus now records stable codes for malformed verbose
  `?ports` declarations, invalid `?ports` tokens, non-positive `?ports`
  widths, malformed `?wiring` list-form endpoints, unsupported `?wiring`
  tokens, malformed top `+constants` identifiers, and non-literal top
  `+enums` values without widening the accepted parser contract.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `prove -Iperl t/126-composition-parser-token-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1: select parser token widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2: widen parser token corpus` | `seven parser-token/top-symbol expected-failure entries; no accepted syntax changed` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added maintained expected-failure entries and stable
  diagnostic-code metadata for composition parser token/top-symbol rejection
  families, then closed the task tree.
