# PPIF-SOURCE-INTENT-NAME-REPORT: Preserve PPIF Top-Level Intent Name In Reports

## Metadata

- Tree ID: `PPIF-SOURCE-INTENT-NAME-REPORT`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Preserve the authored top-level `.ppif`
`(protocol-platform-intent NAME ...)` name in the IAL2 source-anchor/residue
report.

## Non-Goals

- Do not change PPIF syntax acceptance or reject previously accepted scalar
  intent names.
- Do not change generated `.isf`, generated `.fsm`, HDL, check JSON, or
  normalized semantic JSON behavior.
- Do not support multiple `.ppif` objects, aliases, or AXI manager behavior.

## Acceptance Criteria

- `FSM::Adapter::IAL2::PPIF` passes the top-level PPIF intent name into the
  Valid-Ready generator contract.
- The IAL2 report includes that authored name as an additive source-object
  field.
- Focused generator and PPIF parser/CLI tests assert the field for the shipped
  sample.
- PPIF live docs, mdBook, Knowledge Map fact body, task tree, and `MEMORY.md`
  stay aligned.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PPIF-SOURCE-INTENT-NAME-REPORT`
  Status: `done`
  Goal: `Report the authored PPIF top-level intent name.`
  Children: `PPIF-SOURCE-INTENT-NAME-REPORT.1`

- ID: `PPIF-SOURCE-INTENT-NAME-REPORT.1`
  Status: `done`
  Goal: `Add additive PPIF intent-name report field and coverage.`
  Acceptance: `The checked-in PPIF sample emits source_object.intent_name as axi_aw_valid_ready without changing lowering artifacts.`
  Verification: `PASS`
  Commit: `PPIF-SOURCE-INTENT-NAME-REPORT.1: report PPIF intent names`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PPIF-SOURCE-INTENT-NAME-REPORT.1` | `done` | The IAL2 report now preserves the authored top-level PPIF intent name as additive source metadata. |

## Decisions

- `2026-06-12`: Add the intent name as report metadata only. Keep the existing
  generated actor/channel naming and source-object id semantics unchanged.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `PPIF-SOURCE-INTENT-NAME-REPORT.1` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `perl -Iperl -c t/1435-axi-ial2-valid-ready-generator.t`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/1436-ial2-ppif-parser-cli.t`; structured `./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif` probe; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `PPIF-SOURCE-INTENT-NAME-REPORT.1` | `PPIF-SOURCE-INTENT-NAME-REPORT.1: report PPIF intent names` | `pending commit` |

## Changelog

- `2026-06-12`: Completed the PPIF intent-name report leaf.
- `2026-06-12`: Created task tree and selected the PPIF intent-name report leaf.
