# PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE: Document PPIF Semantic JSON CLI Usage

## Metadata

- Tree ID: `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration / Embedding And Public APIs`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Expose the supported `.ppif` `--emit-semantic-json` command in the user-facing
PPIF docs and mdBook IAL2 backlog examples.

## Non-Goals

- Do not change PPIF parser, lowering, report, or semantic JSON behavior.
- Do not add new PPIF syntax, aliases, or AXI manager behavior.
- Do not change generated artifacts.

## Acceptance Criteria

- `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md` shows the `.ppif`
  `--emit-semantic-json` command next to the other public PPIF CLI commands.
- The mdBook IAL2 section lists the same semantic JSON command for the shipped
  first public `.ppif` slice.
- Focused docs/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE`
  Status: `done`
  Goal: `Document PPIF semantic JSON CLI usage.`
  Children: `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1`

- ID: `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1`
  Status: `done`
  Goal: `Add user-facing .ppif --emit-semantic-json examples.`
  Acceptance: `PPIF live doc and mdBook IAL2 section both show the supported semantic JSON command and keep generated .fsm boundary wording intact.`
  Verification: `PASS`
  Commit: `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1: document PPIF semantic JSON command`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1` | `done` | `.ppif` semantic JSON command examples now appear in the PPIF live doc and mdBook. |

## Decisions

- `2026-06-12`: Treat this as documentation sync only; the behavior is already
  owned by previous source-identity and focused-coverage leaves.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1` | `PPIF-SEMANTIC-JSON-CLI-DOC-EXAMPLE.1: document PPIF semantic JSON command` | `pending commit` |

## Changelog

- `2026-06-12`: Completed the PPIF semantic JSON command documentation leaf.
- `2026-06-12`: Created task tree and selected the PPIF semantic JSON command documentation leaf.
