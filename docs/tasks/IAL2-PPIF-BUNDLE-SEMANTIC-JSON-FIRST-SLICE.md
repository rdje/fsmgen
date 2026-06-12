# IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE: Emit PPIF Bundle Semantic JSON

## Metadata

- Tree ID: `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration / Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Ship the first bounded aggregate normalized semantic JSON export for
multi-channel `.ppif` Valid-Ready bundles without selecting a wrapper HDL entry
or hiding an arbitrary generated channel root.

## Non-Goals

- Do not implement bundle wrapper/top HDL generation.
- Do not implement full AXI manager transactions, IDs, ordering, bursts,
  responses, outstanding-window scheduling, or cross-channel dependency rules.
- Do not change single-channel `.ppif` semantic JSON behavior.
- Do not mark bundle HDL generation or `--verify-hdl` as supported.
- Do not add `.pif`, `.ppi`, `.axi`, or other profile suffix aliases.

## Acceptance Criteria

- `--emit-semantic-json` succeeds for a multi-channel `.ppif` Valid-Ready
  bundle and emits a machine-readable aggregate semantic payload.
- The payload preserves public `.ppif` source identity and reports the bundle
  as an aggregate IAL2 semantic root, not as one generated `.fsm` channel.
- The payload exposes channel count, channel objects, generated `.isf` and
  `.fsm` review artifacts, per-channel schedule-report presence, and the
  explicit absence of an HDL entry.
- Default bundle HDL generation, `--verify-hdl`, and single-channel `.ppif`
  semantic JSON behavior remain unchanged.
- Focused PPIF parser/CLI tests, semantic JSON corpus guard, mdBook, Knowledge
  Map, memory, path, and diff gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE`
  Status: `done`
  Goal: `Ship bounded aggregate semantic JSON for PPIF Valid-Ready bundles.`
  Children: `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1`

- ID: `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1`
  Status: `done`
  Goal: `Implement aggregate bundle semantic JSON, tests, docs, facts, and memory sync.`
  Acceptance: `Bundle --emit-semantic-json succeeds with an aggregate PPIF semantic root and no hidden HDL entry while unsupported HDL modes still fail closed.`
  Verification: `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticPayloadContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticReport.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1: emit PPIF bundle semantic JSON`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1` | `done` | Shipped aggregate semantic JSON without wrapper HDL or hidden generated-channel root selection. |

## Decisions

- `2026-06-12`: Treat bundle semantic JSON as an aggregate report-level IAL2
  semantic export. It may summarize per-channel generated artifacts and
  schedule reports, but it must not choose one generated `.fsm` as the semantic
  root or imply HDL is available.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1` | `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticPayloadContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticReport.pm`; `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1` | `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1: emit PPIF bundle semantic JSON` | `pending commit` |

## Changelog

- `2026-06-12`: Created task tree and selected bounded PPIF bundle semantic
  JSON as the next PNT slice.
- `2026-06-12`: Implemented aggregate PPIF bundle semantic JSON, semantic
  payload contract discovery, corpus support accounting, tests, mdBook, facts,
  and memory sync.
