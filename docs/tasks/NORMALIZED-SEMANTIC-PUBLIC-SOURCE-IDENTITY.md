# NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY: Preserve Lowered-Input Source Identity In Semantic JSON

## Metadata

- Tree ID: `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY`
- Status: `done`
- Roadmap lane: `Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Preserve caller-facing source identity and support-accounting matches in
successful public normalized semantic JSON reports for shipped inputs that lower
through generated `.fsm` temporaries.

## Non-Goals

- Do not change the already-owned check JSON behavior.
- Do not change PPIF, ISF, or FSM lowering semantics.
- Do not add new PPIF syntax, aliases, protocol vocabularies, or direct
  IAL2-to-IAL0 lowering paths.
- Do not stabilize the full normalized semantic payload beyond the bounded
  source/support-accounting reporting fix.

## Acceptance Criteria

- `./bin/fsmgen --emit-semantic-json isf/apb_requester.isf` reports the
  resolved checked-in `.isf` path in `source.resolved_path`.
- `./bin/fsmgen --emit-semantic-json ppif/axi_aw_valid_ready.ppif` reports the
  resolved checked-in `.ppif` path in `source.resolved_path`.
- Both successful reports expose matched `support_accounting` entries with the
  expected `source_kind` values.
- Focused tests cover the successful normalized semantic JSON public-source
  identity path.
- README, mdBook, Knowledge Map, and `MEMORY.md` stay aligned with the shipped
  behavior.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY`
  Status: `done`
  Goal: `Preserve public source identity in successful normalized semantic JSON for lowered public inputs.`
  Children: `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1`

- ID: `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1`
  Status: `done`
  Goal: `Make successful normalized semantic JSON use public source paths and corpus matches for .isf/.ppif examples.`
  Acceptance: `Existing .isf/.ppif examples emit semantic JSON with public resolved paths and matched support accounting; docs and fact map are synchronized.`
  Verification: `PASS`
  Commit: `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1: keep lowered-input semantic identity`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1` | `done` | Preserved normalized semantic JSON public source identity after the adjacent check JSON slice exposed the same lowered-input boundary. |

## Decisions

- `2026-06-12`: Keep this slice limited to successful normalized semantic JSON
  reporting for already shipped public examples; broader normalized semantic
  export stabilization stays behind future exact owners.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1` | `perl -Iperl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm`; `perl -Iperl -c perl/FSM/Support/ReportSourceContract.pm`; `prove -Iperl t/303-normalized-semantic-json-supported-corpus.t t/301-check-json-supported-corpus.t t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/312-check-diagnostics-contract.t t/311-normalized-semantic-report-contract.t t/453-report-source-contract-defensive-copy-boundary-audit.t t/1048-report-source-contract-full-surface-defensive-copy-audit.t`; structured probes of `./bin/fsmgen --emit-semantic-json isf/apb_requester.isf` and `ppif/axi_aw_valid_ready.ppif`; `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t`; `scripts/check_memory_architecture.sh` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1` | `NORMALIZED-SEMANTIC-PUBLIC-SOURCE-IDENTITY.1: keep lowered-input semantic identity` | `pending commit` |

## Changelog

- `2026-06-12`: Completed the normalized semantic JSON public source identity slice.
- `2026-06-12`: Created task tree and selected the first executable leaf.
