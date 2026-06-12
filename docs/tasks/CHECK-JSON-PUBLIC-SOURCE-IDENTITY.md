# CHECK-JSON-PUBLIC-SOURCE-IDENTITY: Preserve Public Source Identity In Check JSON

## Metadata

- Tree ID: `CHECK-JSON-PUBLIC-SOURCE-IDENTITY`
- Status: `done`
- Roadmap lane: `Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Make public `--check --json` success reports preserve the original resolved
input source path for file-backed sources that lower through generated `.fsm`
artifacts, and add support-accounting coverage for the shipped `.isf` and
`.ppif` public sample paths.

## Non-Goals

- Do not change `.isf` or `.ppif` lowering behavior.
- Do not change normalized semantic JSON source identity in this slice.
- Do not add new PPIF syntax or aliases.
- Do not broaden the support-accounting corpus beyond the exact shipped
  `.isf` and `.ppif` public examples selected here.

## Acceptance Criteria

- `./bin/fsmgen --strict --check --json isf/apb_requester.isf` reports
  `source.resolved_path` as the resolved `.isf` path, not the temporary
  generated `.fsm` path.
- `./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif` reports
  `source.resolved_path` as the resolved `.ppif` path, not the temporary
  generated `.fsm` path.
- The two public sample paths have matched support-accounting entries with
  source kinds that distinguish `isf` and `ppif`.
- Focused check-JSON and PPIF tests cover the behavior.
- User-facing docs, Knowledge Map, task tree, and MEMORY are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CHECK-JSON-PUBLIC-SOURCE-IDENTITY`
  Status: `done`
  Goal: `Repair check JSON source identity and support-accounting coverage for lowered public inputs.`
  Children: `CHECK-JSON-PUBLIC-SOURCE-IDENTITY.1`

- ID: `CHECK-JSON-PUBLIC-SOURCE-IDENTITY.1`
  Status: `done`
  Goal: `Keep check JSON source identity on the original .isf/.ppif input and add corpus coverage.`
  Acceptance: `Check JSON success reports for public .isf/.ppif examples are source-accurate and support-accounting matched.`
  Verification: `perl -Iperl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/301-check-json-supported-corpus.t t/300-check-json-regression-corpus.t t/299-check-json-diagnostics.t t/297-capability-manifest.t t/1435-axi-ial2-valid-ready-generator.t`; `mdbook build docs/book`; `prove -Iperl t/249-regression-corpus-classified-behavior.t t/304-normalized-semantic-json-regression-corpus.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `CHECK-JSON-PUBLIC-SOURCE-IDENTITY.1: keep lowered-input source identity`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CHECK-JSON-PUBLIC-SOURCE-IDENTITY.1` | `done` | Check JSON now reports original `.isf`/`.ppif` source paths and matched support accounting for the selected public examples. |

## Decisions

- `2026-06-12`: Scope the repair to check JSON only. Normalized semantic JSON
  source identity may need a future exact owner because its semantics and
  downstream expectations are separate.

## Open Questions

- None for this slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | syntax checks; focused check-JSON/PPIF/manifest `prove` cluster; mdBook build; corpus classification and normalized-semantic corpus audits; mdBook/path audit cluster; Knowledge Map; memory architecture; diff check | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `CHECK-JSON-PUBLIC-SOURCE-IDENTITY.1: keep lowered-input source identity` | `pending commit workflow` |

## Changelog

- `2026-06-12`: Created active task tree for check JSON public source
  identity and support-accounting repair.
- `2026-06-12`: Preserved public `.isf`/`.ppif` source paths in successful
  check JSON reports, added exact support-accounting corpus entries, and synced
  docs plus Knowledge Map facts.
