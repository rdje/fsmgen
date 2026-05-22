# R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING: Composition Target Support Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused unsupported composition backend target diagnostic
into the maintained expected-failure regression corpus with stable diagnostics
and public support-accounting visibility.

## Non-Goals

- Do not implement VHDL composition output in this tree.
- Do not change parser acceptance or SystemVerilog/Verilog composition output.
- Do not change direct-root target-language support in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes the unsupported VHDL composition target
  diagnostic into a named expected-failure catalog entry.
- The new entry records stable diagnostic-code metadata and compiled diagnostic
  regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for unsupported composition backend target diagnostics`
  Children: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1`, `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition target-support corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1: select target support widening`

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained expected-failure entry for unsupported composition backend targets`
  Acceptance: `named fixture/catalog entry covers VHDL composition target rejection with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `perl -Iperl -c t/300-check-json-regression-corpus.t`; `perl -Iperl -c t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/114-composition-target-support-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2: widen target support corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2` | `done` | Promoted focused composition target-support diagnostics into maintained corpus coverage. |

## Decisions

- `2026-05-22`: Selected composition target support because
  [t/114-composition-target-support-diagnostics.t](../../t/114-composition-target-support-diagnostics.t)
  already locks the unsupported VHDL composition target diagnostic through the
  pipeline and CLI, while maintained composition-contract corpus coverage now
  accounts for child-entry, child-kind, ports shape/mapping, duplicate
  declaration, child-source, generated-child source-shape, external RTL
  source-shape, and `.rtlif` metadata boundaries.
- `2026-05-22`: Kept VHDL composition as a fail-closed target boundary. The
  regression corpus now carries per-entry target-language metadata so this
  target-specific expected failure executes with `--language vhdl` while the
  default corpus language remains SystemVerilog.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-22` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2` | `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/DiagnosticCodes.pm`; `perl -Iperl -c t/248-regression-corpus-accounting.t`; `perl -Iperl -c t/249-regression-corpus-classified-behavior.t`; `perl -Iperl -c t/300-check-json-regression-corpus.t`; `perl -Iperl -c t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/114-composition-target-support-diagnostics.t`; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/249-regression-corpus-classified-behavior.t`; `prove -Iperl t/300-check-json-regression-corpus.t`; `prove -Iperl t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/297-capability-manifest.t`; `prove -Iperl t/298-diagnostic-code-registry.t`; `prove -Iperl t/320-diagnostics-contract.t t/490-diagnostic-codes-runtime-defensive-copy-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1: select target support widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2: widen target support corpus` | `added VHDL composition target rejection to maintained expected-failure corpus coverage` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
- `2026-05-22`: Added the VHDL composition target rejection fixture/catalog
  entry, stable diagnostic-code metadata, per-entry target-language corpus
  harness support, regression-corpus docs, and mdBook backend-boundary note;
  closed the task tree.
