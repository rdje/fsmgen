# PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE: Lock Focused PPIF Semantic JSON Source Identity

## Metadata

- Tree ID: `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration / Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Make the focused PPIF parser/CLI regression test prove the same normalized
semantic JSON public source-identity behavior that the PPIF documentation now
claims.

## Non-Goals

- Do not change PPIF syntax or the `.ppif -> generated .isf -> generated .fsm`
  lowering chain.
- Do not change normalized semantic report behavior beyond test coverage.
- Do not add `.pif`, `.ppi`, `.axi`, or protocol-specific aliases.

## Acceptance Criteria

- `t/1436-ial2-ppif-parser-cli.t` directly asserts that
  `./bin/fsmgen --emit-semantic-json ppif/axi_aw_valid_ready.ppif` keeps
  `source.resolved_path` on the public `.ppif` path.
- The same focused test asserts matched PPIF support accounting and the
  generated `.fsm` semantic root boundary.
- PPIF public docs, mdBook, task tree, and `MEMORY.md` stay aligned.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE`
  Status: `done`
  Goal: `Focus PPIF CLI semantic JSON coverage on public source identity.`
  Children: `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1`

- ID: `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1`
  Status: `done`
  Goal: `Add focused PPIF semantic JSON source-identity assertions.`
  Acceptance: `t/1436 proves semantic JSON source path, support-accounting match, and generated .fsm semantic-root boundary for the checked-in PPIF sample.`
  Verification: `PASS`
  Commit: `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1: focus PPIF semantic JSON coverage`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1` | `done` | Focused PPIF CLI coverage now carries semantic JSON public source identity, support-accounting, and generated-root assertions. |

## Decisions

- `2026-06-12`: Treat this as a coverage/documentation alignment slice. The
  previous behavior slice already changed the report path; this slice locks the
  PPIF-specific public promise in the PPIF-focused regression test.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1` | `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/303-normalized-semantic-json-supported-corpus.t t/301-check-json-supported-corpus.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1` | `PPIF-SEMANTIC-JSON-FOCUSED-COVERAGE.1: focus PPIF semantic JSON coverage` | `pending commit` |

## Changelog

- `2026-06-12`: Completed the focused PPIF semantic JSON coverage leaf.
- `2026-06-12`: Created task tree and selected the focused PPIF semantic JSON coverage leaf.
