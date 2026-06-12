# IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE: IAL2 PPIF Runnable Sample Fixture

## Metadata

- Tree ID: `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Add a checked-in runnable `.ppif` sample for the first public IAL2
Valid-Ready CLI surface, and make tests/docs use it as the user-visible
example path.

## Non-Goals

- Do not add new PPIF grammar beyond the shipped one-object Valid-Ready shape.
- Do not support `.pif`, `.ppi`, `.axi`, or other aliases.
- Do not implement multiple PPIF objects, platform clauses, or AXI manager
  concurrency rules.
- Do not change the `.ppif -> generated .isf -> generated .fsm` lowering
  chain.

## Acceptance Criteria

- A tracked sample `.ppif` file exists in a repo-local sample directory.
- Focused tests prove the sample parses, emits the IAL2 report, writes
  generated `.isf`/`.fsm` artifacts through `--outdir`, and passes
  `--strict --check --json`.
- The PPIF user-facing docs and mdBook point users at the checked-in sample
  path and keep inline syntax aligned with that file.
- README, Knowledge Map, task tree, and MEMORY are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE`
  Status: `done`
  Goal: `Add and validate the first tracked runnable .ppif sample fixture.`
  Children: `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.1`

- ID: `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.1`
  Status: `done`
  Goal: `Add ppif/axi_aw_valid_ready.ppif, wire it into focused tests, and sync user docs.`
  Acceptance: `The checked-in sample is the canonical first .ppif runnable example and remains lowering-clean through the public CLI.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c bin/fsmgen`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.1: add PPIF sample fixture`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.1` | `done` | The checked-in `ppif/axi_aw_valid_ready.ppif` sample is now the canonical runnable first-slice example. |

## Decisions

- `2026-06-12`: Put the sample under a new top-level `ppif/` directory to
  mirror existing `fsm/` and `isf/` sample-source directories.

## Open Questions

- Broader PPIF sample families remain deferred until their grammar or protocol
  rules ship.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`; `perl -Iperl -c bin/fsmgen`; `prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PPIF-RUNNABLE-SAMPLE-FIXTURE.1: add PPIF sample fixture` | `completed` |

## Changelog

- `2026-06-12`: Created active task tree for the first runnable `.ppif`
  sample-fixture slice.
- `2026-06-12`: Added `ppif/axi_aw_valid_ready.ppif`, wired the focused
  parser/CLI test to the checked-in sample, and synced README, mdBook, PPIF
  docs, fact card, and Knowledge Map.
