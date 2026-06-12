# IAL2-PPIF-PARSER-CLI-FIRST-SLICE: IAL2 PPIF Parser And CLI First Slice

## Metadata

- Tree ID: `IAL2-PPIF-PARSER-CLI-FIRST-SLICE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Ship the first public `.ppif` parser/CLI slice for one AXI Valid-Ready channel
contract, preserving the required `.ppif -> generated .isf -> generated .fsm`
lowering chain.

## Non-Goals

- Do not support `.pif`, `.ppi`, `.axi`, or other aliases in this slice.
- Do not support multiple `.ppif` objects per file.
- Do not implement the full AXI manager or additional AXI rule subsets.
- Do not lower `.ppif` directly to `.fsm`.
- Do not extend the `.isf` parser with IAL2 source forms.

## Acceptance Criteria

- A `.ppif` adapter parses the selected
  `(protocol-platform-intent ... (valid-ready-channel ...))` shape from
  decision `0016`.
- Malformed `.ppif` source fails closed with targeted diagnostics before
  generated `.isf` or `.fsm` behavior is claimed.
- `bin/fsmgen` recognizes `.ppif` inputs as IAL2, generates reviewable `.isf`
  before `.fsm`, and preserves existing `.fsm`/`.isf` behavior.
- `--outdir` materializes the generated `.isf` and generated `.fsm` artifacts
  for `.ppif` inputs.
- `--emit-schedule-json` for `.ppif` emits the IAL2 source-anchor/residue
  report with generated artifact references.
- Focused tests, mdBook, README, Knowledge Map, task tree, and MEMORY are
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-PARSER-CLI-FIRST-SLICE`
  Status: `done`
  Goal: `Implement the first public .ppif parser/CLI slice.`
  Children: `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1`

- ID: `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1`
  Status: `done`
  Goal: `Add .ppif adapter, CLI wiring, focused tests, and docs for one Valid-Ready contract.`
  Acceptance: `.ppif input lowers only through generated .isf into generated .fsm, report/output artifacts are reviewable, and unsupported aliases remain rejected.`
  Verification: `passed`
  Commit: `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1: ship PPIF parser CLI`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1` | `done` | The first public `.ppif` parser/CLI slice is implemented, tested, documented, and ready for commit workflow. |

## Decisions

- `2026-06-12`: Implement only `.ppif` first, because decision `0016` leaves
  `.pif`, `.ppi`, and profile aliases for later exact owners.
- `2026-06-12`: Reuse `FSM::IAL2::ProtocolIntent::ValidReadyChannel` instead
  of duplicating IAL2-to-IAL1 generation logic in the parser or CLI.

## Open Questions

- Future output-directory naming for multiple `.ppif` objects remains deferred
  because this slice supports exactly one object per file.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `perl -Iperl -c bin/fsmgen`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t t/1117-isf-public-lower-result-files-audit.t t/1121-isf-public-cli-schedule-report-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1: ship PPIF parser CLI` | `committed through task-scoped workflow` |

## Changelog

- `2026-06-12`: Created active task tree for the first public `.ppif`
  parser/CLI implementation slice.
- `2026-06-12`: Implemented the `.ppif` adapter, CLI path, focused tests,
  PPIF user-facing docs, mdBook status, Knowledge Map facts, and live status
  updates.
