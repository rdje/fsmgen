# IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE: Implement PPIF Bundle Report Slice

## Metadata

- Tree ID: `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Implement the first bounded multi-channel `.ppif` Valid-Ready bundle behavior
under the selected aggregate contract: parse multiple `valid-ready-channel`
objects, generate per-channel review artifacts, emit an aggregate IAL2 report,
and keep default HDL/aggregate semantic modes fail-closed in this slice. Later
owners shipped aggregate semantic JSON and the aggregate wrapper/top HDL entry.

## Non-Goals

- Do not implement AXI manager transactions, transaction IDs, ordering rules,
  bursts, response matching, outstanding-window scheduling, or channel
  dependency enforcement.
- Do not implement a wrapper/top actor or aggregate HDL entry in this slice.
- Do not implement aggregate normalized semantic JSON in this slice.
- Do not accept `.pif`, `.ppi`, `.axi`, or protocol-profile suffix aliases.
- Do not change the shipped single-channel `.ppif` result/report behavior.

## Acceptance Criteria

- A `.ppif` file with multiple `valid-ready-channel` clauses parses into an
  aggregate `protocol_intent.valid_ready_bundle` result.
- Each channel still lowers through generated `.isf` into generated `.fsm`;
  no direct `.ppif -> .fsm` path is introduced.
- `--emit-schedule-json` emits the aggregate IAL2 bundle report.
- `--outdir` materializes every generated channel `.isf` and `.fsm` review
  artifact, then stops before HDL with an explicit bundle-review message in
  this slice.
- Default HDL generation and multi-channel `--emit-semantic-json` fail closed
  with targeted diagnostics in this slice; later owners shipped both behaviors.
- The existing single-channel `.ppif` behavior and tests remain unchanged.
- Focused parser/CLI tests, mdBook, Knowledge Map, memory, path, and diff
  gates pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE`
  Status: `done`
  Goal: `Ship the first bounded multi-channel .ppif bundle report/review-artifact behavior.`
  Children: `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1`

- ID: `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1`
  Status: `done`
  Goal: `Implement aggregate bundle parsing, reporting, review-artifact materialization, and fail-closed unsupported CLI modes.`
  Acceptance: `The code, tests, docs, task tree, mdBook, Knowledge Map, generated map, and MEMORY pointer agree on the shipped bounded bundle behavior and explicit HDL/semantic deferrals.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -c bin/fsmgen`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1: ship PPIF bundle report slice`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1` | `done` | Shipped the bounded bundle report/review-artifact behavior without wrapper HDL. |

## Decisions

- `2026-06-12`: Keep this first behavior slice limited to aggregate reports
  and review artifacts. Default HDL and aggregate semantic JSON remain
  targeted fail-closed modes.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -c bin/fsmgen`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1` | `IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1: ship PPIF bundle report slice` | `pending commit` |

## Changelog

- `2026-06-12`: Created task tree and selected the first bounded PPIF
  Valid-Ready bundle behavior leaf.
- `2026-06-12`: Implemented bounded multi-channel PPIF bundle parsing,
  aggregate reporting, review-artifact materialization, check JSON accounting,
  and targeted fail-closed default HDL/semantic modes.
